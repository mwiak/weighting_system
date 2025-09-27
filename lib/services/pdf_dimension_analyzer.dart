import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/page_dimensions.dart';

/// Analyzes PDF files to extract exact dimensions and metadata
/// without depending on external PDF packages
class PdfDimensionAnalyzer {
  static const String _pdfHeader = '%PDF-';
  static const int _maxHeaderSearch = 1024;

  /// Extract PDF document information including page dimensions
  static Future<PdfDocumentInfo?> analyzePdf(Uint8List pdfBytes) async {
    try {
      if (!_isPdfFile(pdfBytes)) {
        debugPrint('Not a valid PDF file');
        return null;
      }

      final parser = _PdfParser(pdfBytes);
      return await parser.parse();
    } catch (e) {
      debugPrint('Error analyzing PDF: $e');
      return null;
    }
  }

  /// Quick check to determine if bytes represent a PDF file
  static bool _isPdfFile(Uint8List bytes) {
    if (bytes.length < 8) return false;

    final header = String.fromCharCodes(bytes.take(5));
    return header == _pdfHeader;
  }

  /// Extract just the first page dimensions quickly
  static Future<PageSize?> getFirstPageSize(Uint8List pdfBytes) async {
    try {
      final parser = _PdfParser(pdfBytes);
      return await parser.getFirstPageSize();
    } catch (e) {
      debugPrint('Error getting first page size: $e');
      return null;
    }
  }

  /// Get PDF version
  static double? getPdfVersion(Uint8List pdfBytes) {
    if (pdfBytes.length < 8) return null;

    final header = String.fromCharCodes(pdfBytes.take(8));
    if (!header.startsWith(_pdfHeader)) return null;

    final versionStr = header.substring(5, 8);
    return double.tryParse(versionStr);
  }
}

/// Internal PDF parser for extracting dimensions
class _PdfParser {
  final Uint8List _bytes;
  final String _content;
  late final Map<String, _PdfObject> _objects;

  _PdfParser(this._bytes) : _content = _sanitizeContent(_bytes);

  /// Parse the PDF and extract document information
  Future<PdfDocumentInfo> parse() async {
    await _parseObjects();

    final pages = await _extractPages();
    final metadata = _extractMetadata();

    return PdfDocumentInfo(
      pages: pages,
      title: metadata['Title'] ?? 'Unknown',
      creator: metadata['Creator'] ?? 'Unknown',
      creationDate: _parseDate(metadata['CreationDate']),
      version: PdfDimensionAnalyzer.getPdfVersion(_bytes) ?? 1.4,
    );
  }

  /// Extract just the first page size for quick analysis
  Future<PageSize?> getFirstPageSize() async {
    await _parseObjects();

    final pages = await _extractPages();
    if (pages.isEmpty) return null;

    return pages.first.size;
  }

  /// Convert bytes to sanitized string for parsing
  static String _sanitizeContent(Uint8List bytes) {
    // Convert to string, handling binary content
    final content = String.fromCharCodes(bytes);
    return content;
  }

  /// Parse PDF objects from content
  Future<void> _parseObjects() async {
    _objects = <String, _PdfObject>{};

    // Simple regex to find object definitions
    final objectPattern = RegExp(r'(\d+)\s+(\d+)\s+obj\s*(.+?)\s*endobj',
                                dotAll: true);

    final matches = objectPattern.allMatches(_content);

    for (final match in matches) {
      final id = match.group(1)!;
      final generation = match.group(2)!;
      final content = match.group(3)!;

      final objectId = '$id $generation';
      _objects[objectId] = _PdfObject(id, generation, content);
    }
  }

  /// Extract page information
  Future<List<PdfPageInfo>> _extractPages() async {
    final pages = <PdfPageInfo>[];

    // Find the catalog object
    final catalog = _findCatalog();
    if (catalog == null) return pages;

    // Find pages object
    final pagesObj = _findPages(catalog);
    if (pagesObj == null) return pages;

    // Extract individual pages
    final pageRefs = _extractPageReferences(pagesObj);

    for (int i = 0; i < pageRefs.length; i++) {
      final pageObj = _objects[pageRefs[i]];
      if (pageObj != null) {
        final pageInfo = _extractPageInfo(pageObj, i + 1);
        if (pageInfo != null) {
          pages.add(pageInfo);
        }
      }
    }

    return pages;
  }

  /// Find the document catalog
  _PdfObject? _findCatalog() {
    for (final obj in _objects.values) {
      if (obj.content.contains('/Type /Catalog')) {
        return obj;
      }
    }
    return null;
  }

  /// Find the pages object from catalog
  _PdfObject? _findPages(_PdfObject catalog) {
    final pagesRef = _extractReference(catalog.content, '/Pages');
    return pagesRef != null ? _objects[pagesRef] : null;
  }

  /// Extract page references from pages object
  List<String> _extractPageReferences(_PdfObject pagesObj) {
    final refs = <String>[];

    // Look for /Kids array
    final kidsMatch = RegExp(r'/Kids\s*\[\s*([^\]]+)\]')
        .firstMatch(pagesObj.content);

    if (kidsMatch != null) {
      final kidsContent = kidsMatch.group(1)!;
      final refPattern = RegExp(r'(\d+)\s+(\d+)\s+R');

      for (final match in refPattern.allMatches(kidsContent)) {
        final ref = '${match.group(1)} ${match.group(2)}';
        refs.add(ref);
      }
    }

    return refs;
  }

  /// Extract page information from page object
  PdfPageInfo? _extractPageInfo(_PdfObject pageObj, int pageNumber) {
    try {
      // Extract MediaBox for page dimensions
      final mediaBox = _extractMediaBox(pageObj.content);
      if (mediaBox == null) return null;

      final size = PageSize.fromPoints(
        mediaBox[2] - mediaBox[0], // width
        mediaBox[3] - mediaBox[1], // height
        name: 'Page $pageNumber',
      );

      final orientation = size.widthMm > size.heightMm
          ? Orientation.landscape
          : Orientation.portrait;

      return PdfPageInfo(
        size: size,
        margins: const PrintMargins.zero(),
        pageNumber: pageNumber,
        orientation: orientation,
      );
    } catch (e) {
      debugPrint('Error extracting page info: $e');
      return null;
    }
  }

  /// Extract MediaBox coordinates
  List<double>? _extractMediaBox(String content) {
    final mediaBoxMatch = RegExp(r'/MediaBox\s*\[\s*([\d\.\s]+)\]')
        .firstMatch(content);

    if (mediaBoxMatch != null) {
      final coords = mediaBoxMatch.group(1)!
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();

      if (coords.length >= 4) {
        return coords.take(4).toList();
      }
    }

    return null;
  }

  /// Extract reference from content
  String? _extractReference(String content, String key) {
    final refMatch = RegExp('$key\\s+(\\d+)\\s+(\\d+)\\s+R')
        .firstMatch(content);

    return refMatch != null
        ? '${refMatch.group(1)} ${refMatch.group(2)}'
        : null;
  }

  /// Extract document metadata
  Map<String, String> _extractMetadata() {
    final metadata = <String, String>{};

    // Find Info object
    for (final obj in _objects.values) {
      if (obj.content.contains('/Title') ||
          obj.content.contains('/Creator') ||
          obj.content.contains('/CreationDate')) {

        // Extract title
        final titleMatch = RegExp(r'/Title\s*\(([^)]+)\)')
            .firstMatch(obj.content);
        if (titleMatch != null) {
          metadata['Title'] = titleMatch.group(1)!;
        }

        // Extract creator
        final creatorMatch = RegExp(r'/Creator\s*\(([^)]+)\)')
            .firstMatch(obj.content);
        if (creatorMatch != null) {
          metadata['Creator'] = creatorMatch.group(1)!;
        }

        // Extract creation date
        final dateMatch = RegExp(r'/CreationDate\s*\(([^)]+)\)')
            .firstMatch(obj.content);
        if (dateMatch != null) {
          metadata['CreationDate'] = dateMatch.group(1)!;
        }
      }
    }

    return metadata;
  }

  /// Parse PDF date format
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;

    try {
      // PDF date format: D:YYYYMMDDHHmmSSOHH'mm
      if (dateStr.startsWith('D:') && dateStr.length >= 16) {
        final year = int.parse(dateStr.substring(2, 6));
        final month = int.parse(dateStr.substring(6, 8));
        final day = int.parse(dateStr.substring(8, 10));
        final hour = dateStr.length > 10 ? int.parse(dateStr.substring(10, 12)) : 0;
        final minute = dateStr.length > 12 ? int.parse(dateStr.substring(12, 14)) : 0;
        final second = dateStr.length > 14 ? int.parse(dateStr.substring(14, 16)) : 0;

        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
    }

    return null;
  }
}

/// Simple PDF object representation
class _PdfObject {
  final String id;
  final String generation;
  final String content;

  _PdfObject(this.id, this.generation, this.content);

  @override
  String toString() => 'Object $id $generation';
}
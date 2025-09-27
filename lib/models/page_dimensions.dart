/// Page dimension models for precise printing control
///
/// Handles conversion between different measurement units and provides
/// exact dimensions for PDF pages and printer paper sizes.

class PageSize {
  final double widthMm;
  final double heightMm;
  final String name;
  final Orientation orientation;

  const PageSize({
    required this.widthMm,
    required this.heightMm,
    required this.name,
    this.orientation = Orientation.portrait,
  });

  /// Convert to points (PDF standard: 1 point = 1/72 inch)
  double get widthPoints => widthMm * 2.834645669;
  double get heightPoints => heightMm * 2.834645669;

  /// Convert to inches
  double get widthInches => widthMm / 25.4;
  double get heightInches => heightMm / 25.4;

  /// Get pixel dimensions at specific DPI
  int widthPixels(int dpi) => (widthInches * dpi).round();
  int heightPixels(int dpi) => (heightInches * dpi).round();

  /// Check if this page fits within another page size
  bool fitsWithin(PageSize paperSize) {
    return widthMm <= paperSize.widthMm && heightMm <= paperSize.heightMm;
  }

  /// Get rotated version of this page size
  PageSize get rotated => PageSize(
        widthMm: heightMm,
        heightMm: widthMm,
        name: '$name (Rotated)',
        orientation: orientation == Orientation.portrait
            ? Orientation.landscape
            : Orientation.portrait,
      );

  /// Check if dimensions match another page size (with tolerance)
  bool matches(PageSize other, {double toleranceMm = 1.0}) {
    return (widthMm - other.widthMm).abs() <= toleranceMm &&
           (heightMm - other.heightMm).abs() <= toleranceMm;
  }

  /// Standard paper sizes
  static const PageSize a3 = PageSize(
    widthMm: 297,
    heightMm: 420,
    name: 'A3',
  );

  static const PageSize a4 = PageSize(
    widthMm: 210,
    heightMm: 297,
    name: 'A4',
  );

  static const PageSize a5 = PageSize(
    widthMm: 148,
    heightMm: 210,
    name: 'A5',
  );

  static const PageSize letter = PageSize(
    widthMm: 215.9,
    heightMm: 279.4,
    name: 'Letter',
  );

  static const PageSize legal = PageSize(
    widthMm: 215.9,
    heightMm: 355.6,
    name: 'Legal',
  );

  static const PageSize tabloid = PageSize(
    widthMm: 279.4,
    heightMm: 431.8,
    name: 'Tabloid',
  );

  /// Create from points (PDF native units)
  factory PageSize.fromPoints(double widthPoints, double heightPoints, {String? name}) {
    return PageSize(
      widthMm: widthPoints / 2.834645669,
      heightMm: heightPoints / 2.834645669,
      name: name ?? 'Custom',
    );
  }

  /// Create from pixels at specific DPI
  factory PageSize.fromPixels(int widthPixels, int heightPixels, int dpi, {String? name}) {
    final widthInches = widthPixels / dpi;
    final heightInches = heightPixels / dpi;
    return PageSize(
      widthMm: widthInches * 25.4,
      heightMm: heightInches * 25.4,
      name: name ?? 'Custom',
    );
  }

  @override
  String toString() {
    return '$name: ${widthMm.toStringAsFixed(1)}mm × ${heightMm.toStringAsFixed(1)}mm';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageSize &&
           other.widthMm == widthMm &&
           other.heightMm == heightMm;
  }

  @override
  int get hashCode => widthMm.hashCode ^ heightMm.hashCode;
}

enum Orientation {
  portrait,
  landscape,
}

/// Detailed print margins information
class PrintMargins {
  final double leftMm;
  final double rightMm;
  final double topMm;
  final double bottomMm;

  const PrintMargins({
    required this.leftMm,
    required this.rightMm,
    required this.topMm,
    required this.bottomMm,
  });

  const PrintMargins.zero()
      : leftMm = 0,
        rightMm = 0,
        topMm = 0,
        bottomMm = 0;

  const PrintMargins.uniform(double marginMm)
      : leftMm = marginMm,
        rightMm = marginMm,
        topMm = marginMm,
        bottomMm = marginMm;

  /// Get printable area given a page size
  PageSize printableArea(PageSize pageSize) {
    return PageSize(
      widthMm: pageSize.widthMm - leftMm - rightMm,
      heightMm: pageSize.heightMm - topMm - bottomMm,
      name: '${pageSize.name} (Printable)',
    );
  }

  @override
  String toString() {
    return 'Margins: L:${leftMm}mm R:${rightMm}mm T:${topMm}mm B:${bottomMm}mm';
  }
}

/// PDF page information with exact dimensions
class PdfPageInfo {
  final PageSize size;
  final PrintMargins margins;
  final int pageNumber;
  final Orientation orientation;
  final bool hasTransparency;
  final List<String> fonts;

  const PdfPageInfo({
    required this.size,
    required this.margins,
    required this.pageNumber,
    required this.orientation,
    this.hasTransparency = false,
    this.fonts = const [],
  });

  /// Check if this page can be printed on given paper without scaling
  bool canPrintActualSize(PageSize paperSize, {PrintMargins? printerMargins}) {
    final requiredSize = printerMargins != null
        ? PageSize(
            widthMm: size.widthMm + printerMargins.leftMm + printerMargins.rightMm,
            heightMm: size.heightMm + printerMargins.topMm + printerMargins.bottomMm,
            name: 'Required',
          )
        : size;

    return requiredSize.fitsWithin(paperSize);
  }

  @override
  String toString() {
    return 'Page $pageNumber: $size, $orientation';
  }
}

/// Complete PDF document information
class PdfDocumentInfo {
  final List<PdfPageInfo> pages;
  final String title;
  final String creator;
  final DateTime? creationDate;
  final bool isEncrypted;
  final double version;

  const PdfDocumentInfo({
    required this.pages,
    required this.title,
    required this.creator,
    this.creationDate,
    this.isEncrypted = false,
    this.version = 1.4,
  });

  /// Get the largest page size in the document
  PageSize? get maxPageSize {
    if (pages.isEmpty) return null;

    double maxWidth = 0;
    double maxHeight = 0;
    String name = 'Mixed';

    for (final page in pages) {
      if (page.size.widthMm > maxWidth) maxWidth = page.size.widthMm;
      if (page.size.heightMm > maxHeight) maxHeight = page.size.heightMm;
    }

    return PageSize(
      widthMm: maxWidth,
      heightMm: maxHeight,
      name: name,
    );
  }

  /// Check if all pages have the same size
  bool get hasUniformPageSizes {
    if (pages.isEmpty) return true;
    final firstSize = pages.first.size;
    return pages.every((page) => page.size == firstSize);
  }

  /// Get unique page sizes in the document
  List<PageSize> get uniquePageSizes {
    final sizes = <PageSize>{};
    for (final page in pages) {
      sizes.add(page.size);
    }
    return sizes.toList();
  }

  @override
  String toString() {
    return 'PDF: "$title" (${pages.length} pages, v$version)';
  }
}
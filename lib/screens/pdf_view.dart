import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OnlinePDFView extends StatefulWidget {
  final String pdfUrl;
  final bool isLocal;
  const OnlinePDFView({super.key, required this.pdfUrl, this.isLocal = false});

  @override
  State<OnlinePDFView> createState() => _OnlinePDFView();
}

class _OnlinePDFView extends State<OnlinePDFView> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  Uint8List? _documentBytes;
  OverlayEntry? _overlayEntry;
  double yOffset = 0.0;
  double xOffset = 0.0;
  final Color _contextMenuColor = const Color(0xFFFFFFFF);
  final Color _textColor = const Color(0xFF000000);
  bool loading = true;

  @override
  void initState() {
    if (widget.isLocal) {
      getPdfBytes(widget.pdfUrl);
    } else {
      getPdfBytesFromWeb(widget.pdfUrl);
    }
    super.initState();
  }

  ///Get the PDF document as bytes from local project asset
  void getPdfBytes(String url) async {
    // final ByteData bytes = await DefaultAssetBundle.of(context).load(url);
    // _documentBytes = bytes.buffer.asUint8List();
    _documentBytes = await File(url).readAsBytes();
    setState(() {
      loading = false;
    });
  }

  ///Get the PDF document as bytes from internet URL
  void getPdfBytesFromWeb(String url) async {
    _documentBytes = await http.readBytes(Uri.parse(url));
    setState(() {
      loading = false;
    });
  }

  ///Add the annotation in PDF document
  Widget _addAnnotation(String? annotationType, String? selectedText) {
    return SizedBox(
      height: 30,
      width: 100,
      child: RawMaterialButton(
        onPressed: () async {
          _checkAndCloseContextMenu();
          await Clipboard.setData(ClipboardData(text: selectedText!));
          _drawAnnotation(annotationType);
        },
        child: Text(
          annotationType!,
          style: TextStyle(
            color: _textColor,
            fontSize: 10,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  ///Draw the annotation in PDF document
  void _drawAnnotation(String? annotationType) {
    final PdfDocument document = PdfDocument(inputBytes: _documentBytes);
    switch (annotationType) {
      case 'Highlight':
        {
          _pdfViewerKey.currentState!
              .getSelectedTextLines()
              .forEach((pdfTextLine) {
            final PdfPage page = document.pages[pdfTextLine.pageNumber];
            final PdfRectangleAnnotation rectangleAnnotation =
                PdfRectangleAnnotation(
                    pdfTextLine.bounds, 'Highlight Annotation',
                    author: 'Syncfusion',
                    color: PdfColor.fromCMYK(0, 0, 255, 0),
                    innerColor: PdfColor.fromCMYK(0, 0, 255, 0),
                    opacity: 0.5);
            page.annotations.add(rectangleAnnotation);
            page.annotations.flattenAllAnnotations();
            xOffset = _pdfViewerController.scrollOffset.dx;
            yOffset = _pdfViewerController.scrollOffset.dy;
          });
          final List<int> bytes = document.saveSync();
          setState(() {
            _documentBytes = Uint8List.fromList(bytes);
          });
        }
        break;
      case 'Underline':
        {
          _pdfViewerKey.currentState!
              .getSelectedTextLines()
              .forEach((pdfTextLine) {
            final PdfPage page0 = document.pages[pdfTextLine.pageNumber];
            final PdfLineAnnotation lineAnnotation = PdfLineAnnotation(
              [
                pdfTextLine.bounds.left.toInt(),
                (document.pages[pdfTextLine.pageNumber].size.height -
                        pdfTextLine.bounds.bottom)
                    .toInt(),
                pdfTextLine.bounds.right.toInt(),
                (document.pages[pdfTextLine.pageNumber].size.height -
                        pdfTextLine.bounds.bottom)
                    .toInt()
              ],
              'Underline Annotation',
              author: 'Syncfusion',
              innerColor: PdfColor(0, 255, 0),
              color: PdfColor(0, 255, 0),
            );
            page0.annotations.add(lineAnnotation);
            page0.annotations.flattenAllAnnotations();
            xOffset = _pdfViewerController.scrollOffset.dx;
            yOffset = _pdfViewerController.scrollOffset.dy;
          });
          final List<int> bytes = document.saveSync();
          setState(() {
            _documentBytes = Uint8List.fromList(bytes);
          });
        }
        break;
      case 'Strikethrough':
        {
          _pdfViewerKey.currentState!
              .getSelectedTextLines()
              .forEach((pdfTextLine) {
            final PdfPage page0 = document.pages[pdfTextLine.pageNumber];
            final PdfLineAnnotation lineAnnotation = PdfLineAnnotation(
              [
                pdfTextLine.bounds.left.toInt(),
                ((document.pages[pdfTextLine.pageNumber].size.height -
                            pdfTextLine.bounds.bottom) +
                        (pdfTextLine.bounds.height / 2))
                    .toInt(),
                pdfTextLine.bounds.right.toInt(),
                ((document.pages[pdfTextLine.pageNumber].size.height -
                            pdfTextLine.bounds.bottom) +
                        (pdfTextLine.bounds.height / 2))
                    .toInt()
              ],
              'Strikethrough Annotation',
              author: 'Syncfusion',
              innerColor: PdfColor(255, 0, 0),
              color: PdfColor(255, 0, 0),
            );
            page0.annotations.add(lineAnnotation);
            page0.annotations.flattenAllAnnotations();
            xOffset = _pdfViewerController.scrollOffset.dx;
            yOffset = _pdfViewerController.scrollOffset.dy;
          });
          final List<int> bytes = document.saveSync();
          setState(() {
            _documentBytes = Uint8List.fromList(bytes);
          });
        }
        break;
    }
  }

  /// Show Context menu with annotation options.
  void _showContextMenu(
    BuildContext context,
    PdfTextSelectionChangedDetails? details,
  ) {
    final RenderBox renderBoxContainer =
        context.findRenderObject()! as RenderBox;
    const double kContextMenuHeight = 90;
    const double kContextMenuWidth = 100;
    const double kHeight = 18;
    final Offset containerOffset = renderBoxContainer.localToGlobal(
      renderBoxContainer.paintBounds.topLeft,
    );
    if (details != null &&
            containerOffset.dy < details.globalSelectedRegion!.topLeft.dy ||
        (containerOffset.dy <
                details!.globalSelectedRegion!.center.dy -
                    (kContextMenuHeight / 2) &&
            details.globalSelectedRegion!.height > kContextMenuWidth)) {
      double top = 0.0;
      double left = 0.0;
      final Rect globalSelectedRect = details.globalSelectedRegion!;
      if ((globalSelectedRect.top) > MediaQuery.of(context).size.height / 2) {
        top = globalSelectedRect.topLeft.dy +
            details.globalSelectedRegion!.height +
            kHeight;
        left = globalSelectedRect.bottomLeft.dx;
      } else {
        top = globalSelectedRect.height > kContextMenuWidth
            ? globalSelectedRect.center.dy - (kContextMenuHeight / 2)
            : globalSelectedRect.topLeft.dy +
                details.globalSelectedRegion!.height +
                kHeight;
        left = globalSelectedRect.height > kContextMenuWidth
            ? globalSelectedRect.center.dx - (kContextMenuWidth / 2)
            : globalSelectedRect.bottomLeft.dx;
      }
      final OverlayState overlayState = Overlay.of(context, rootOverlay: true);
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: top,
          left: left,
          child: Container(
            decoration: BoxDecoration(
              color: _contextMenuColor,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.14),
                  blurRadius: 2,
                  offset: Offset(0, 0),
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.12),
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            constraints: const BoxConstraints.tightFor(
                width: kContextMenuWidth, height: kContextMenuHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _addAnnotation('Highlight', details.selectedText),
                _addAnnotation('Underline', details.selectedText),
                _addAnnotation('Strikethrough', details.selectedText),
              ],
            ),
          ),
        ),
      );
      overlayState.insert(_overlayEntry!);
    }
  }

  /// Check and close the context menu.
  void _checkAndCloseContextMenu() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncfusion Flutter PDF Viewer'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _documentBytes != null
              ? SfPdfViewer.memory(
                  _documentBytes!,
                  key: _pdfViewerKey,
                  controller: _pdfViewerController,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    _pdfViewerController.jumpTo(
                        xOffset: xOffset, yOffset: yOffset);
                  },
                  onTextSelectionChanged:
                      (PdfTextSelectionChangedDetails details) {
                    if (details.selectedText == null && _overlayEntry != null) {
                      _checkAndCloseContextMenu();
                    } else if (details.selectedText != null &&
                        _overlayEntry == null) {
                      _showContextMenu(context, details);
                    }
                  },
                )
              : Container(),
    );
  }
}

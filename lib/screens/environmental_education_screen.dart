import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pdf_view.dart';

class EnvironmentalEducationScreen extends StatefulWidget {
  const EnvironmentalEducationScreen({super.key});

  @override
  State<EnvironmentalEducationScreen> createState() =>
      _EnvironmentalEducationScreenState();
}

class _EnvironmentalEducationScreenState
    extends State<EnvironmentalEducationScreen> {
  final String apiUrl =
      'https://www.eschool2go.org/api/v1/project/ba7ea038-2e2d-4472-a7c2-5e4dad7744e3?path=Environmental%20Education';
  List<EnvironmentalEducationData> dataList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    requestStoragePermission();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> dataListJson = json.decode(response.body);

      dataList = dataListJson.map((item) {
        final String title = item['title'];
        final String downloadUrl = item['download_url'];
        return EnvironmentalEducationData(title, downloadUrl, false);
      }).toList();
      dataList.sort(
          (a, b) => a.title.substring(0, 2).compareTo(b.title.substring(0, 2)));
      setState(() {});
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<bool> downloadFile(String downloadUrl, String title) async {
    debugPrint('Download URL: $downloadUrl');
    final dio = Dio();
    final response = await dio.get(
      downloadUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode == 200) {
      final bytes = response.data as List<int>;
      try {
        final downloadsDirectory = await getExternalStorageDirectory();
        final filePath = '${downloadsDirectory!.path}/$title';
        await File(filePath).writeAsBytes(Uint8List.fromList(bytes));
        return true; // Return true to indicate successful download.
      } catch (e) {
        debugPrint('Error writing file: $e');
      }
    } else {
      debugPrint('Failed to download file: ${response.statusCode}');
    }
    return false;
  }

  Future<void> openFileIfExist(String fileName) async {
    final appDocumentsDirectory = await getExternalStorageDirectory();
    final filePath = '${appDocumentsDirectory!.path}/$fileName';
    final file = File(filePath);
    debugPrint('File path: $filePath');
    if (await file.exists()) {
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlinePDFView(
            pdfUrl: filePath,
            isLocal: true,
          ),
        ),
      );
    } else {
      debugPrint('File does not exist');
    }
  }

  Future<bool> checkIfFileExistsInFolder(String fileName) async {
    final downloadsDirectory = await getExternalStorageDirectory();
    final filePath = '${downloadsDirectory!.path}/$fileName';
    final file = File(filePath);
    return await file.exists();
  }

  Future<void> requestStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      debugPrint('Permission granted');
    } else {
      debugPrint('Permission denied');
    }
  }

  Future<void> openOnlinePdfViewer(String pdfUrl) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlinePDFView(pdfUrl: pdfUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Education'),
      ),
      body: dataList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                final data = dataList[index];
                final title = data.title;
                return FutureBuilder(
                  future: checkIfFileExistsInFolder('$title.pdf'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.data == true) {
                      data.isDownloaded = true; // Update the flag.
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.all(8.0),
                      // height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey[200],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                              data.isDownloaded
                                  ? IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        // Delete the file from the folder.
                                        final downloadsDirectory =
                                            await getExternalStorageDirectory();
                                        final filePath =
                                            '${downloadsDirectory!.path}/$title.pdf';
                                        final file = File(filePath);
                                        if (await file.exists()) {
                                          await file.delete();
                                          setState(() {
                                            data.isDownloaded = false;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.delete),
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          data.isDownloaded
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.9,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.green,
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          openFileIfExist('$title.pdf');
                                        },
                                        child: const Text(
                                          'Read Offline',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.42,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.green,
                                      ),
                                      child: TextButton(
                                        onPressed: () async {
                                          final success = await downloadFile(
                                              data.downloadUrl, '$title.pdf');
                                          if (success) {
                                            setState(() {
                                              data.isDownloaded = true;
                                            });
                                          }
                                        },
                                        child: const Text(
                                          'Download',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.42,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.grey,
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          openOnlinePdfViewer(data.downloadUrl);
                                        },
                                        child: const Text(
                                          'View Online',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class EnvironmentalEducationData {
  final String title;
  final String downloadUrl;
  bool isDownloaded; // Add a flag to track whether the file is downloaded.

  EnvironmentalEducationData(this.title, this.downloadUrl, this.isDownloaded);
}

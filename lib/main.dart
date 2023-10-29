import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Finder App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const DogFinderPage(title: 'The Dog Finder'),
    );
  }
}

class DogFinderPage extends StatefulWidget {
  const DogFinderPage({super.key, required this.title});

  final String title;

  @override
  State<DogFinderPage> createState() => _DogFinderPageState();
}

class _DogFinderPageState extends State<DogFinderPage> {
  String? dogSrc;
  List<String> linkList = [];
  String? errorText;
  bool loading = true;
  Map<String, List<String>> dogBreeds = {};
  String? selectedBreed;
  String? selectedSubBreed;
  String selectedResponseType = 'random';
  bool get randomImage => selectedResponseType == 'random';
  // bool randomImage = true; // false is image list
  TextEditingController breedTextController = TextEditingController();
  TextEditingController subBreedTextController = TextEditingController();
  TextEditingController responseType = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchDogBreeds();
    });
  }

  @override
  Widget build(BuildContext context) {
    double inputWidth = 500;
    List<DropdownMenuEntry> breedOptions = buildBreeds();
    List<DropdownMenuEntry> subBreedOptions = buildSubBreeds();

    bool validBreed = selectedBreed == null ||
        breedOptions
            .where((element) => element.value == breedTextController.text)
            .isNotEmpty;
    bool validSubBreed = subBreedOptions.isEmpty ||
        subBreedOptions
            .where((element) => element.value == subBreedTextController.text)
            .isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: separatedChildren(
                8,
                [
                  FocusableActionDetector(
                    onFocusChange: (focused) {
                      if (focused) {
                        setState(() {
                          responseType.text = '';
                        });
                      }
                    },
                    child: DropdownMenu(
                      onSelected: (respType) {
                        setState(() {
                          if (respType != null) selectedResponseType = respType;
                          dogSrc = null;
                          linkList = [];
                        });
                      },
                      controller: responseType,
                      width: inputWidth,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'random', label: 'Singular'),
                        DropdownMenuEntry(value: 'list', label: 'List'),
                      ],
                      label: const Text(
                        'Response Type',
                      ),
                      initialSelection: selectedResponseType,
                    ),
                  ),
                  SizedBox(
                    width: 500,
                    height: 500,
                    child: randomImage
                        ? dogSrc == null
                            ? Image.asset(
                                'DefaultDog.jpg',
                              )
                            : Image.network(dogSrc!)
                        : Center(
                            child: linkList.isNotEmpty
                                ? ListView.builder(
                                    itemBuilder: (ctx, i) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 2, 0, 2),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedResponseType = 'random';
                                              dogSrc = linkList[i];
                                            });
                                          },
                                          child: Text(
                                            linkList[i],
                                          ),
                                        ),
                                      );
                                    },
                                    itemCount: linkList.length,
                                  )
                                : const Text('No links yet'),
                          ),
                  ),
                  dogSrc == null
                      ? Container()
                      : Text(
                          '${selectedSubBreed != null ? '$selectedSubBreed, ' : ''}${selectedBreed ?? ''}'),
                  SizedBox(
                    width: inputWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: separatedChildren(16, [
                        FocusableActionDetector(
                          onFocusChange: (focused) {
                            if (focused) {
                              setState(() {
                                breedTextController.text = '';
                              });
                            }
                          },
                          child: DropdownMenu(
                            errorText: validBreed ||
                                    breedTextController.value.text.isEmpty
                                ? null
                                : 'Please select a valid breed',
                            controller: breedTextController,
                            onSelected: (breed) {
                              setState(() {
                                selectedBreed = breed;
                              });
                            },
                            width: inputWidth,
                            enableFilter: true,
                            dropdownMenuEntries: buildBreeds(),
                            initialSelection: null,
                            label: const Text(
                              'Breed',
                            ),
                          ),
                        ),
                        FocusableActionDetector(
                          onFocusChange: (focused) {
                            if (focused) {
                              setState(() {
                                subBreedTextController.text = '';
                              });
                            }
                          },
                          child: DropdownMenu(
                            onSelected: (subBreed) {
                              setState(() {
                                selectedSubBreed = subBreed;
                              });
                            },
                            controller: subBreedTextController,
                            enabled: subBreedOptions.isNotEmpty,
                            errorText: validSubBreed
                                ? null
                                : 'Please select a valid sub-breed',
                            width: inputWidth,
                            dropdownMenuEntries: subBreedOptions,
                            label: const Text(
                              'Sub-breed',
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: validBreed && validSubBreed
                              ? () {
                                  setState(() {
                                    loading = true;
                                    dogSrc = null;
                                    linkList = [];
                                  });
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    randomImage
                                        ? fetchDog(
                                            selectedBreed, selectedSubBreed)
                                        : fetchDogLinks(
                                            selectedBreed, selectedSubBreed);
                                  });
                                }
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.all(
                              16,
                            ),
                            child: Text('Dog searcher'),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: errorText != null,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: ColoredBox(
                color: Colors.red.withOpacity(0.2),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white),
                    child: SizedBox(
                      width: 250,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(errorText ?? ''),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    dogSrc = null;
                                    errorText = null;
                                    loading = true;
                                    selectedBreed = null;
                                    selectedSubBreed = null;
                                    breedTextController.text = '';
                                    subBreedTextController.text = '';

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      fetchDogBreeds();
                                    });
                                  });
                                },
                                child: const Text('Reset'))
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: loading,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: ColoredBox(
                color: Colors.green.withOpacity(0.2),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white),
                    child: const SizedBox(
                      width: 250,
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: RefreshProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<DropdownMenuEntry> buildBreeds() {
    List<DropdownMenuEntry> entries = [
      const DropdownMenuEntry(value: null, label: 'Any')
    ];
    for (var entry in dogBreeds.entries) {
      entries.add(
        DropdownMenuEntry(value: entry.key, label: entry.key),
      );
    }
    return entries;
  }

  List<DropdownMenuEntry> buildSubBreeds() {
    if (selectedBreed == null) return [];
    if (dogBreeds[selectedBreed] == null) return [];
    if (dogBreeds[selectedBreed]!.isEmpty) return [];

    List<DropdownMenuEntry> entries = [
      const DropdownMenuEntry(value: null, label: 'Any')
    ];
    for (var breed in dogBreeds[selectedBreed]!) {
      entries.add(
        DropdownMenuEntry(value: breed, label: breed),
      );
    }
    return entries;
  }

  List<Widget> separatedChildren(double space, List<Widget> children,
      {Axis axis = Axis.vertical, bool applyToTartAndEnd = false}) {
    List<Widget> spacedChildren = [];
    if (applyToTartAndEnd) spacedChildren.add(spacer(space, axis));

    for (int i in List.generate(children.length, (index) => index)) {
      if (i != 0) spacedChildren.add(spacer(space, axis));
      spacedChildren.add(children[i]);
    }

    if (applyToTartAndEnd) spacedChildren.add(spacer(space, axis));
    return spacedChildren;
  }

  SizedBox spacer(double space, Axis axis) => SizedBox(
        width: axis == Axis.horizontal ? space : 0,
        height: axis == Axis.vertical ? space : 0,
      );

  Future fetchDogBreeds() async {
    Map<String, List<String>> breeds = {};
    try {
      final response =
          await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
      if (response.statusCode == 200) {
        for (var entry
            in (jsonDecode(response.body)["message"] as Map).entries) {
          breeds[entry.key] = (entry.value as List).cast<String>();
        }
      } else {
        errorText = 'Failed to fetch dog breeds';
        loading = false;
      }
      setState(() {
        dogBreeds = breeds;
        loading = false;
      });
    } catch (_) {
      setState(() {
        errorText = 'Failed to fetch dog breeds';
        loading = false;
      });
    }
  }

  Future fetchDog(String? breed, String? subBreed) async {
    try {
      String url = 'https://dog.ceo/api/breeds/image/random';

      if (breed != null) {
        url = 'https://dog.ceo/api/breed/$breed/images/random';
      }

      if (subBreed != null) {
        url = 'https://dog.ceo/api/breed/$breed/$subBreed/images/random';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          dogSrc = jsonDecode(response.body)["message"];
          loading = false;
        });
      } else {
        setState(() {
          errorText = 'Failed to fetch image';
          loading = false;
        });
      }
    } catch (_) {
      setState(() {
        errorText = 'Failed to fetch image';
        loading = false;
      });
    }
  }

  Future fetchDogLinks(String? breed, String? subBreed) async {
    try {
      String url = 'https://dog.ceo/api/breeds/image/random/10';

      if (breed != null) {
        url = 'https://dog.ceo/api/breed/$breed/images/random/10';
      }

      if (subBreed != null) {
        url = 'https://dog.ceo/api/breed/$breed/$subBreed/images/random/10';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        linkList.clear();
        setState(() {
          for (var link in jsonDecode(response.body)["message"]) {
            linkList.add(link);
          }
          loading = false;
        });
      } else {
        setState(() {
          errorText = 'Failed to fetch image';
          loading = false;
        });
      }
    } catch (_) {
      setState(() {
        errorText = 'Failed to fetch image';
        loading = false;
      });
    }
  }
}

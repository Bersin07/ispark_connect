import 'package:flutter/material.dart';
import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa_json_flutter.dart';

class DictionaryPage extends StatefulWidget {
  @override
  _DictionaryPageState createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final dMSAJson = DictionaryMSAFlutter();
  DictEntry _entry = DictEntry('', [], [], []);
  bool _isLoading = false;
  bool _isError = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Call this method to lookup a word
  void lookupWord() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    DictEntry? tmp;
    final txt = _controller.text.trim();
    if (await dMSAJson.hasEntry(txt)) {
      tmp = await dMSAJson.getEntry(txt);
    }

    setState(() {
      _isLoading = false;
      if (tmp != null) {
        _entry = tmp;
      } else {
        _isError = true;
        _entry = DictEntry('', [], [], []);
      }
    });
  }

  // Render the content of _entry
  Widget _buildEntry() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError || _entry.word.isEmpty) {
      return const Center(
        child: Text(
          'No definition found',
          style: TextStyle(fontSize: 18.0, color: Colors.redAccent),
        ),
      );
    }

    return Expanded(
      child: ListView(
        children: [
          Text(
            'Word: ${_entry.word}',
            style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF009688)),
          ),
          const SizedBox(height: 16.0),
          ..._entry.meanings.map((meaning) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Part of Speech: ${meaning.pos}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                        ),
                        const SizedBox(height: 4.0),
                        Text('Description: ${meaning.description}', style: const TextStyle(fontSize: 16.0)),
                        if (meaning.hasMeanings())
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Contextual Meanings: ${meaning.meanings.join(', ')}', style: const TextStyle(fontSize: 16.0, color: Colors.orange)),
                          ),
                        if (meaning.hasExamples())
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Examples: ${meaning.examples.join(', ')}', style: const TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dictionary',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Enter a word',
                labelStyle: TextStyle(color: _isFocused ? Colors.orange : Colors.grey),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF009688)),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  lookupWord();
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: const Color(0xFF009688), // text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              ),
              child: const Text('Search', style: TextStyle(fontSize: 16.0)),
            ),
            const SizedBox(height: 16.0),
            _buildEntry(),
          ],
        ),
      ),
    );
  }
}
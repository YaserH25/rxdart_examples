import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main(List<String> args) {
  runApp(const MaterialApp(home: HomeApp()));
}

enum TypeOfThing { animal, person }

@immutable
class Thing {
  final TypeOfThing type;
  final String name;

  const Thing({required this.type, required this.name});
}

@immutable
class Bloc {
  final Sink<TypeOfThing?> setTypeOfThing;
  final Stream<TypeOfThing?> currentTypeOfThing;
  final Stream<Iterable<Thing>> things;

  const Bloc._({
    required this.setTypeOfThing,
    required this.currentTypeOfThing,
    required this.things,
  });

  void dispose() {
    setTypeOfThing.close();
  }

  factory Bloc({
    required Iterable<Thing> things,
  }) {
    final typeOfThingsSubject = BehaviorSubject<TypeOfThing?>();

    final filteredThings = typeOfThingsSubject
        .debounceTime(const Duration(milliseconds: 300))
        .map<Iterable<Thing>>((typeOfThings) {
      if (typeOfThings != null) {
        return things.where((element) => element.type == typeOfThings);
      } else {
        return things;
      }
    }).startWith(things);
    return Bloc._(
        setTypeOfThing: typeOfThingsSubject.sink,
        currentTypeOfThing: typeOfThingsSubject.stream,
        things: filteredThings);
  } 
}

const things = [
  Thing(type: TypeOfThing.person, name: 'Foo'),
  Thing(type: TypeOfThing.person, name: 'Bar'),
  Thing(type: TypeOfThing.person, name: 'Baz'),
  Thing(type: TypeOfThing.animal, name: 'Bunz'),
  Thing(type: TypeOfThing.animal, name: 'Fluffers'),
  Thing(type: TypeOfThing.animal, name: 'Woofz'),
];

class HomeApp extends StatefulWidget {
  const HomeApp({super.key});

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  late final Bloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = Bloc(things: things);
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('home'),
      ),
      body: Column(
        children: [
          StreamBuilder<TypeOfThing?>(
            stream: bloc.currentTypeOfThing,
            builder: (context, snapshot) {
              final selectedTypeOfThing = snapshot.data;
              return Wrap(
                children: TypeOfThing.values
                    .map(
                      (typeOfThing) => FilterChip(
                        selectedColor: Colors.blueAccent,
                        onSelected: (selected) {
                          final type = selected ? typeOfThing : null;
                          bloc.setTypeOfThing.add(type);
                        },
                        label: Text(typeOfThing.name),
                        selected: selectedTypeOfThing == typeOfThing,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          Expanded(
              child: StreamBuilder<Iterable<Thing>>(
            stream: bloc.things,
            builder: (context, snapshot) {
              final things = snapshot.data ?? [];
              return ListView.builder(
                itemCount: things.length,
                itemBuilder: (context, index) {
                  final thing = things.elementAt(index);
                  return ListTile(
                    title: Text(thing.name),
                    subtitle: Text(thing.type.name),
                  );
                },
              );
            },
          ))
        ],
      ),
    );
  }
}

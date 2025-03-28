import 'dart:convert';
import 'dart:mirrors';

import 'id.dart';

class Dog {
  const Dog(
    this.id,
    this.name,
    this.age,
  );

  @Id("auto")
  final int id;

  final String name;
  final int age;
}

void main() {
  // Create a map, with a self counting MapEntry
  Map<int, Dog> liste = <int, Dog>{1: Dog(1, 'Humphrey', 5)};
  liste[liste.length] = Dog(2, 'Fred', 0);
  liste[liste.length] = Dog(3, 'Corrado', 8);

  print('Map with dogs: ${liste}');

  // Retrieve dog 'Fred'
  Dog fred = liste[1]!;

  printAnnotationValue();

  printAnnotationVariableValue(fred);
}

/// Read the value from an annotation defined at a variable inside a class
void printAnnotationValue() {
  // Use reflectClass to check only the class and not an defined object
  final myClassMirror = reflectClass(Dog);

  // Iterate through all declared variables of an class and
  // find the one with the Symbol [#id].
  // The Symbol is the variable name in this case [id] or [name], [age]
  final myVariableMirror =
      myClassMirror.declarations.entries.firstWhere((declaration) {
    return declaration.key == #id;
  }).value;

  // Take the first InstanceMirror from the variable metadata. That's
  // our Id-Annotation.
  // Get the annotation "object" with reflectee and cast it to our [Id] class
  final myAnnotation = myVariableMirror.metadata.first.reflectee as Id;
  // Call [generationType] variable from Id-Class
  print('generationType One: ${myAnnotation.generationType}');
}

/// Read the value from an annotation defined at a variable inside a class
/// and also get the value of the variable
/// In this example we have the object [fred]. We want to get the [generationType]
/// value from our annotation class and also retrieve the variable value from
/// [fred.id]
void printAnnotationVariableValue(Dog fred) {
  // Use reflect() because we have a defined object which we want to analyse
  InstanceMirror instanceMirror = reflect(fred);

  // First retrieve the variables of the class and find the one with the
  // our Annotation-Class Id()
  final myVariableMirror =
      instanceMirror.type.declarations.entries.firstWhere((declaration) {
    return declaration.value.metadata.any((element) => element.reflectee is Id);
  }).value;

  final myAnnotation = myVariableMirror.metadata.first.reflectee as Id;
  print('generationType: ${myAnnotation.generationType}');

  int myVariableValueId =
      instanceMirror.getField(myVariableMirror.simpleName).reflectee;
  print('VariableValue with annotation id: ${myVariableValueId}');
}

void dynamicMethodInvocation(Object obj, String methodName, List<dynamic> arguments) {
  final instance = reflect(obj);
  final method = Symbol(methodName);
  
  // Methode dynamisch aufrufen
  final result = instance.invoke(method, arguments);
  print('Ergebnis des Aufrufs von $methodName: ${result.reflectee}');
}

Map<String, dynamic> objectToMap(Object obj) {
  final mirror = reflect(obj);
  final classMirror = mirror.type;
  final map = <String, dynamic>{};
  
  classMirror.declarations.forEach((symbol, declarationMirror) {
    if (declarationMirror is VariableMirror && !declarationMirror.isStatic) {
      final name = MirrorSystem.getName(symbol);
      final value = mirror.getField(symbol).reflectee;
      map[name] = value;
    }
  });
  
  return map;
}

String objectToJson(Object obj) {
  final map = objectToMap(obj);
  return jsonEncode(map);
}

// Automatic creation of object with type X
T createInstance<T>(Type type, List<dynamic> constructorArguments) {
  final classMirror = reflectClass(type);
  final instance = classMirror.newInstance(Symbol(''), constructorArguments);
  return instance.reflectee as T;
}
import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';

final _dartFmt = DartFormatter();

Spec mainMethod() {
  final method = Method(
    (b) {
      b.name = "main";
      b.body = const Code("runApp(const MyGeneratedApp());");
      b.returns = refer("void");
    },
  );

  return method;
}

Expression materialAppWidget() {
  final materialAppWidget = refer("MaterialApp").returned.call(
    [],
    {
      "title": literal("Flutter demo"),
      "theme": refer("ThemeData").call([], {"primarySwatch": refer("Colors.blue")}),
      "home": refer(myStatefulWidgetGenerator()[0].name).constInstance(
        [],
        {"title": literal("Flutter demo home page")},
      )
    },
  );

  return materialAppWidget;
}

Expression scaffoldWidget() {
  final materialAppWidget = refer("Scaffold").returned.call(
    [],
    {
      "appBar": refer("AppBar").call(
        [],
        {
          "title": refer("Text").call(
            [
              refer("widget").property("title"),
            ],
          ),
        },
      ),
      "body": refer("Text").constInstance(
        [
          literal("Hello world!"),
        ],
      ),
    },
  );

  return materialAppWidget;
}

// stateful home page widget
List<Class> myStatefulWidgetGenerator() {
  const statefulWidgetName = "MyHomePage";
  const stateName = "_" + statefulWidgetName + "State";

  final myHomePageStateClass = Class(
    (b) {
      b.extend = TypeReference(
        (tb) {
          tb.symbol = "State";
          tb.types.add(
            refer(statefulWidgetName),
          );
        },
      );
      b.name = stateName;
      b.methods.add(
        Method(
          (m) {
            m.name = "build";
            m.lambda = false;
            m.returns = refer("Widget");
            m.annotations.add(refer("override"));
            m.requiredParameters.add(
              Parameter(
                (p) {
                  p.name = "context";
                  p.type = refer("BuildContext");
                },
              ),
            );
            m.body = scaffoldWidget().statement;
          },
        ),
      );
    },
  );

  final myHomePageClass = Class(
    (b) {
      b.extend = refer("StatefulWidget");
      b.name = "MyHomePage";
      b.constructors.add(
        Constructor(
          (c) {
            c.optionalParameters.addAll(
              [
                Parameter(
                  (p) {
                    p.type = refer("Key?");
                    p.named = true;
                    p.name = "key";
                  },
                ),
                Parameter(
                  (p) {
                    p.required = true;
                    p.named = true;
                    p.name = "title";
                    p.toThis = true;
                  },
                ),
              ],
            );
            c.constant = true;
            c.initializers.add(
              refer("super").call([], {'key': refer("key")}).code,
            );
          },
        ),
      );
      b.fields.add(
        Field(
          (f) {f.name = "title"; f.type = refer("String"); f.modifier = FieldModifier.final$;},
        ),
      );
      b.methods.add(
        Method(
          (m) {
            m.name = "createState";
            m.lambda = true;
            m.returns = TypeReference(
              (tb) {
                tb.symbol = "State";
                tb.types.add(
                  refer(statefulWidgetName),
                );
              },
            );
            m.annotations.add(
              refer("override"),
            );
            m.body = refer(stateName).call([]).code;
          },
        ),
      );
    },
  );

  return [myHomePageClass, myHomePageStateClass];
}

// stateless root widget
Class myStatelessWidgetGenerator() {
  final myGeneratorClass = Class(
    (b) {
      b.extend = refer("StatelessWidget");
      b.name = "MyGeneratedApp";
      b.constructors.add(
        Constructor(
          (c) {
            c.optionalParameters.add(
              Parameter(
                (p) {
                  p.type = refer("Key?");
                  p.named = true;
                  p.name = "key";
                },
              ),
            );
            c.constant = true;
            c.initializers.add(
              refer("super").call([], {'key': refer("key")}).code,
            );
          },
        ),
      );
      b.methods.add(
        Method(
          (m) {
            m.name = "build";
            m.lambda = false;
            m.returns = refer("Widget");
            m.annotations.add(refer("override"));
            m.requiredParameters.add(
              Parameter(
                (p) {
                  p.name = "context";
                  p.type = refer("BuildContext");
                },
              ),
            );
            m.body = materialAppWidget().statement;
          },
        ),
      );
    },
  );

  return myGeneratorClass;
}

void main(List<String> args) async {
  var mainOutput = mainMethod();
  var rootStatelessWidgetGenerator = myStatelessWidgetGenerator();
  var homeStatefulWidgetGenerator = myStatefulWidgetGenerator();

  final library = Library(
    (b) {
      b.body.addAll([
        mainOutput,
        rootStatelessWidgetGenerator,
        ...homeStatefulWidgetGenerator,
      ]);
      b.directives.add(
        Directive.import("package:flutter/material.dart"),
      );
    },
  );

  var outputCode = _dartFmt.format('${library.accept(DartEmitter.scoped(
    useNullSafetySyntax: true,
    orderDirectives: true,
  ))}');

  final file = File(absolute("lib", "code_builder", "output", "main.dart"));

  var writer = file.openWrite();
  writer.write(outputCode);

  await writer.flush();
  await writer.close();
}

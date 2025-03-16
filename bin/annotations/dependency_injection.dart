import 'dart:mirrors';

// Eine Annotation für die zu injizierenden Abhängigkeiten
class Inject {
  const Inject();
}

// Unser einfaches Dependency Injection Container
class DependencyContainer {
  // Speichert Instanzen nach Typ
  static final Map<Type, Object> _instances = {};
  
  // Registriert eine Instanz für einen bestimmten Typ
  static void register<T>(T instance) {
    _instances[T] = instance as Object;
  }
  
  // Holt eine registrierte Instanz
  static T resolve<T>() {
    final instance = _instances[T];
    if (instance == null) {
      throw Exception('Keine Instanz vom Typ $T registriert');
    }
    return instance as T;
  }
  
  // Injiziert alle mit @Inject markierten Properties
  static void injectDependencies(Object obj) {
    final instanceMirror = reflect(obj);
    final classMirror = instanceMirror.type;
    
    // Durchlaufe alle Deklarationen in der Klasse
    classMirror.declarations.forEach((symbol, declarationMirror) {
      // Prüfe, ob es sich um eine Variable handelt
      if (declarationMirror is VariableMirror && !declarationMirror.isFinal) {
        // Prüfe, ob die Variable mit @Inject annotiert ist
        for (final metadata in declarationMirror.metadata) {
          if (metadata.reflectee is Inject) {
            // Bestimme den Typ der Variable
            final propertyType = declarationMirror.type.reflectedType;
            
            try {
              // Hole eine Instanz des benötigten Typs
              final dependency = _instances[propertyType];
              if (dependency != null) {
                // Setze die Dependency in das Objekt
                instanceMirror.setField(symbol, dependency);
                print('Injiziert: ${MirrorSystem.getName(symbol)} vom Typ $propertyType');
              } else {
                print('Warnung: Keine Instanz vom Typ $propertyType gefunden');
              }
            } catch (e) {
              print('Fehler bei der Injektion von $propertyType: $e');
            }
          }
        }
      }
    });
  }
}

// Ein Service-Interface
abstract class Logger {
  void log(String message);
}

// Eine konkrete Implementierung des Loggers
class ConsoleLogger implements Logger {
  @override
  void log(String message) {
    print('LOG: $message');
  }
}

// Ein Service, der den Logger verwendet
class UserService {
  @Inject()
  late Logger logger; // Mit @Inject markiert für DI
  
  void createUser(String username) {
    // Verwende den injizierten Logger
    logger.log('Benutzer erstellt: $username');
  }
}

// Ein Service, der von UserService abhängt
class AuthenticationService {
  @Inject()
  late UserService userService; // Mit @Inject markiert für DI
  
  @Inject()
  late Logger logger; // Mit @Inject markiert für DI
  
  void registerUser(String username, String password) {
    logger.log('Registrierung begonnen für: $username');
    userService.createUser(username);
    logger.log('Registrierung abgeschlossen für: $username');
  }
}

void main() {
  // Registriere Dienste im Container
  DependencyContainer.register<Logger>(ConsoleLogger());
  
  // Erstelle UserService und injiziere Abhängigkeiten
  final userService = UserService();
  DependencyContainer.injectDependencies(userService);
  
  // Registriere UserService im Container
  DependencyContainer.register<UserService>(userService);
  
  // Erstelle AuthenticationService und injiziere Abhängigkeiten
  final authService = AuthenticationService();
  DependencyContainer.injectDependencies(authService);
  
  // Teste die Services
  authService.registerUser('max_mustermann', 'sicheres_passwort123');
}
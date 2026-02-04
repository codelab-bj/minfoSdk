#import <Foundation/Foundation.h>

/// Gestionnaire des ressources du SDK Minfo
/// S'assure que tous les fichiers de données du moteur Cifrasoft
/// sont présents et accessibles depuis le bundle de l'application
@interface ResourceManager : NSObject

/// Chemin du répertoire de ressources du SDK
+ (NSString *)bundleResourcePath;

/// Vérifie et prépare tous les fichiers de données nécessaires
+ (BOOL)ensureResourcesAvailable:(NSError **)error;

/// Chemin complet d'une ressource
+ (NSString *)pathForResource:(NSString *)resourceName;

/// Initialise les chemins pour le moteur Cifrasoft
+ (BOOL)initializeCifrasoftPaths:(NSError **)error;

@end

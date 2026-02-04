#import "ResourceManager.h"

@implementation ResourceManager

+ (NSString *)bundleResourcePath {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *frameworkBundle = [bundle pathForResource:@"minfo_sdk" ofType:@"bundle"];
    
    if (frameworkBundle) {
        return [frameworkBundle stringByAppendingPathComponent:@"Resources"];
    }
    
    // Fallback: Utiliser le chemin principal du bundle si pas de sub-bundle
    return [bundle resourcePath];
}

+ (BOOL)ensureResourcesAvailable:(NSError **)error {
    NSString *resourcePath = [self bundleResourcePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Vérifier que le répertoire existe
    BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:resourcePath isDirectory:&isDirectory];
    
    if (!exists || !isDirectory) {
        NSLog(@"[ResourceManager] ⚠️ Répertoire de ressources introuvable: %@", resourcePath);
        
        // Créer le répertoire s'il n'existe pas
        NSError *createError = nil;
        if (![fileManager createDirectoryAtPath:resourcePath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&createError]) {
            if (error) {
                *error = createError;
            }
            return NO;
        }
    }
    
    NSLog(@"[ResourceManager] ✅ Ressources vérifiées: %@", resourcePath);
    return YES;
}

+ (NSString *)pathForResource:(NSString *)resourceName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *resourcePath = [bundle pathForResource:resourceName ofType:nil];
    
    if (!resourcePath) {
        // Chercher dans le sous-bundle
        NSString *frameworkBundle = [bundle pathForResource:@"minfo_sdk" ofType:@"bundle"];
        if (frameworkBundle) {
            NSBundle *subBundle = [NSBundle bundleWithPath:frameworkBundle];
            resourcePath = [subBundle pathForResource:resourceName ofType:nil];
        }
    }
    
    return resourcePath;
}

+ (BOOL)initializeCifrasoftPaths:(NSError **)error {
    NSLog(@"[ResourceManager] 🔧 Initialisation des chemins Cifrasoft");
    
    // S'assurer que les ressources sont disponibles
    if (![self ensureResourcesAvailable:error]) {
        NSLog(@"[ResourceManager] ❌ Échec de la préparation des ressources");
        return NO;
    }
    
    NSString *resourcePath = [self bundleResourcePath];
    NSLog(@"[ResourceManager] 📁 Chemin des ressources: %@", resourcePath);
    
    // Énumérer les ressources disponibles
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *listError = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:resourcePath error:&listError];
    
    if (contents) {
        NSLog(@"[ResourceManager] 📋 Fichiers disponibles: %@", contents);
    } else if (listError) {
        NSLog(@"[ResourceManager] ⚠️ Erreur lors de l'énumération: %@", listError);
    }
    
    return YES;
}

@end

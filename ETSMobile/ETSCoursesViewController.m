//
//  ETSCoursesViewController.m
//  ETSMobile
//
//  Created by Jean-Philippe Martin on 2013-10-20.
//  Copyright (c) 2013 ApplETS. All rights reserved.
//

#import "ETSCoursesViewController.h"
#import "ETSCourse.h"
#import "ETSEvaluation.h"
#import "ETSAuthenticationViewController.h"
#import "ETSCourseCell.h"
#import "ETSSessionHeader.h"
#import "NSURLRequest+API.h"
#import "ETSCourseDetailViewController.h"
#import "ETSMenuViewController.h"
#import "ETSCalendar.h"
#import <QuartzCore/QuartzCore.h>

#import <Crashlytics/Crashlytics.h>

@interface ETSCoursesViewController ()
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSIndexPath *lastSelectedIndexPath;
@property (strong, nonatomic) NSMutableDictionary *courseResults; // Temporary results (on 100%) are saved here.

//@property (nonatomic, assign) BOOL shouldHideResults;
//self.shouldHideResults = false;

//[self.secondSynchronization synchronize:&error]; (start refresh??)

/*ETSSynchronization *secondSynchronization = [[ETSSynchronization alloc] init];
 secondSynchronization.request = [NSURLRequest requestForEvalEnseignement: self.course];
 secondSynchronization.entityName = @"EvalEnseignement";
 secondSynchronization.objectsKeyPath = @"d.liste";
 
 self.secondSynchronization = secondSynchronization;
 self.secondSynchronization.delegate = self;       (viewDidLoad) */


/*    NSLog(@"liste Evaluations : \n %@", [results valueForKey:@"listeEvaluations"]);
 
 if([results valueForKey:@"listeEvaluations"]) {
 
 
 // On doit créer une liste de toutes les évaluations avec le dictionnaire des résultats.
 // On doit parcourir cette liste et en sélectionner les évaluations correspondant au cours de la vue s'il y en a.
 // Si le booléen EstComplete de l'une de ses évaluations est à false et que la date d'aujourd'hui se trouve entre la date de début et la date de fin, on doit afficher une AlertView.
 
 self.shouldHideResults = true;
 
 dispatch_async(dispatch_get_main_queue(), ^{
 [self.tableView reloadData];
 });
 
 }
 else { // comportement "normal"
 
 
 (didReceiveDictionnary)*/



//[self.secondSynchronization synchronize:&error]; (startRefresh ETSTableViewController)

@end

@implementation ETSCoursesViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.courseResults == nil) {
        self.courseResults = [[NSMutableDictionary alloc] initWithCapacity:4];
    }
    self.title =  NSLocalizedString(@"Notes", nil);
    
    NSString *session = self.readCurrentSession;
    
    self.cellIdentifier = @"CourseIdentifier";
    
    ETSSynchronization *synchronization = [[ETSSynchronization alloc] init];
    synchronization.request = [NSURLRequest requestForCourses];
    synchronization.entityName = @"Course";
    synchronization.compareKey = @"id";
    synchronization.objectsKeyPath = @"d.liste";
    synchronization.ignoredAttributes = @[@"results", @"resultOn100", @"mean", @"median", @"std", @"percentile"];
    self.synchronization = synchronization;
    self.synchronization.delegate = self;
    
    
    ETSSynchronization *evalSynchronization = [[ETSSynchronization alloc] init];
    evalSynchronization.request = [NSURLRequest requestForEvalEnseignement: session];
    evalSynchronization.entityName = @"EvalEnseignement";
    evalSynchronization.objectsKeyPath = @"d.liste";
    
    self.evalSynchronization = evalSynchronization;
    self.evalSynchronization.delegate = self;

    
    if (![ETSAuthenticationViewController passwordInKeychain] || ![ETSAuthenticationViewController usernameInKeychain]) {
        ETSAuthenticationViewController *ac = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardAuthenticationViewController];
        ac.delegate = self;
        [self.navigationController pushViewController:ac animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [Answers logContentViewWithName:@"Courses notes"
                        contentType:@"Courses"
                          contentId:@"ETS-Courses"
                   customAttributes:@{}];
    
    if (self.lastSelectedIndexPath) {
        [self configureCell:[self.collectionView cellForItemAtIndexPath:self.lastSelectedIndexPath] atIndexPath:self.lastSelectedIndexPath];
    }
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Course" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    fetchRequest.fetchBatchSize = 24;
    
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"acronym" ascending:YES]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"order" cacheName:nil];
    self.fetchedResultsController = aFetchedResultsController;
    _fetchedResultsController.delegate = self;

    NSError *error;
    if (![_fetchedResultsController performFetch:&error]) {
        // FIXME: Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _fetchedResultsController;
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ETSCourse *course = [self.fetchedResultsController objectAtIndexPath:indexPath];

    ETSCourseCell *courseCell = (ETSCourseCell *)cell;

    if ([course.grade length] > 0) {
        courseCell.gradeLabel.text = course.grade;
    }
    // If we comeback from a course detail view, get the result on 100%. Save it in the courseResults dictionnary
    // and print it in the cell.
    else if (([course.resultOn100 floatValue] > 0 && [[course totalEvaluationWeighting] floatValue])
             || [self.courseResults objectForKey:(NSString *) course.acronym] != nil) {
        NSNumber *percent = @([course.resultOn100 floatValue]/[[course totalEvaluationWeighting] floatValue]*100);
        if ([percent integerValue] > 0) {
            [self.courseResults setValue:(NSNumber *)percent forKey:(NSString *) course.acronym];
        }
        courseCell.gradeLabel.text = [NSString stringWithFormat:@"%lu %%",
                                      (long)[[self.courseResults valueForKey:(NSString *)course.acronym] integerValue]];
    } else {
        courseCell.gradeLabel.text = @"—";
    }
    
    courseCell.acronymLabel.text = course.acronym;
    
    courseCell.layer.cornerRadius = 2.0f;
    courseCell.layer.borderColor = [UIColor colorWithRed:190.0f/255.0f green:0.0f/255.0f blue:10.0f/255.0f alpha:1].CGColor;
    courseCell.layer.borderWidth = 1.0f;
}

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor lightGrayColor];
}

- (void)collectionView:(UICollectionView *)colView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        ETSSessionHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SessionHeaderIdentifier" forIndexPath:indexPath];
        
        ETSCourse *course = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        if (([course.season integerValue] == 0)) {
            headerView.sessionLabel.text = NSLocalizedString(@"Autres", nil);
        } else {
            NSString *session = nil;
            if ([course.season integerValue] == 1)      session = NSLocalizedString(@"Hiver", nil);
            else if ([course.season integerValue] == 2) session = NSLocalizedString(@"Été", nil);
            else if ([course.season integerValue] == 3) session = NSLocalizedString(@"Automne", nil);
            headerView.sessionLabel.text = [NSString stringWithFormat:@"%@ %@", session, course.year];
        }

        return headerView;
    }
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ETSCourseDetailViewController *vc = [segue destinationViewController];
    
    // Always get a fresh fetchedResultsController before changing context.
    self.fetchedResultsController = nil;
    self.fetchedResultsController = [self fetchedResultsController];
    vc.course = [self.fetchedResultsController objectAtIndexPath:[self.collectionView indexPathsForSelectedItems][0]];
    
    vc.managedObjectContext = self.managedObjectContext;
    self.lastSelectedIndexPath = [self.collectionView indexPathsForSelectedItems][0];

    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    ETSCourse *course = [self.fetchedResultsController objectAtIndexPath:[self.collectionView indexPathsForSelectedItems][0]];
    
    
    
    if ([course.acronym isEqualToString:@"LOG121"]){ //à remplacer par la liste des cours à évaluer
        
        NSLog(@"------------------------  %@  !!!!!!!!!",course.acronym);
        
        
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Période d'évaluation"
                                                           message:@"Vous ne pouvez pas accéder à vos notes présentement car vous n'avez pas encore complété l'évaluation en ligne pour ce cours."
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
        return NO;
    }
    else {
        return YES;
    }
}

- (void)synchronization:(ETSSynchronization *)synchronization didReceiveObject:(NSDictionary *)object forManagedObject:(NSManagedObject *)managedObject
{
    
    
    NSLog(@"!!!!!!!!! ------------    liste Evaluations : \n %@   -------------------- !!!!!", [object valueForKey:@"listeEvaluations"]);

    if ([managedObject isKindOfClass:[ETSEvaluation class]]) return;
    
    ETSCourse *course = (ETSCourse *)managedObject;
    course.year = @([[object[@"session"] substringFromIndex:1] integerValue]);
    
    NSString *seasonString = [object[@"session"] substringToIndex:1];
    if ([seasonString isEqualToString:@"H"])      course.season = @1;
    else if ([seasonString isEqualToString:@"É"]) course.season = @2;
    else if ([seasonString isEqualToString:@"A"]) course.season = @3;
    else course.season = @0;
    
    if ([seasonString isEqualToString:@"H"])      course.order = [NSString stringWithFormat:@"%@-%@", course.year, @"1"];
    else if ([seasonString isEqualToString:@"É"]) course.order = [NSString stringWithFormat:@"%@-%@", course.year, @"2"];
    else if ([seasonString isEqualToString:@"A"]) course.order = [NSString stringWithFormat:@"%@-%@", course.year, @"3"];
    else course.order = @"00000";
    
    course.id = [NSString stringWithFormat:@"%@%@",course.order, course.acronym];
}

- (void)controllerDidAuthenticate:(ETSAuthenticationViewController *)controller
{
    self.synchronization.request = [NSURLRequest requestForCourses];
    [super controllerDidAuthenticate:controller];
    [self.collectionView reloadData];
}

- (ETSSynchronizationResponse)synchronization:(ETSSynchronization *)synchronization validateJSONResponse:(NSDictionary *)response
{
    return [ETSAuthenticationViewController validateJSONResponse:response];
}

- (NSString *)readCurrentSession
{
    NSArray *fetchedObjects;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Calendar" inManagedObjectContext:context];
    [fetch setEntity:entityDescription];
    
    NSError * error = nil;
    fetchedObjects = [context executeFetchRequest:fetch error:&error];
    
    if(fetchedObjects)
    {
        ETSCalendar *currentCalendar = [fetchedObjects objectAtIndex:0];
        
        return currentCalendar.session;
    }

    else
    {
        return nil;
    }
}

@end

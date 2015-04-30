//
//  KDBMasterViewController.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBMasterViewController.h"

@interface KDBMasterViewController ()
@end

@implementation KDBMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

}


#pragma mark - UIDataSourceModelAssociation
- (NSString *) modelIdentifierForElementAtIndexPath:(NSIndexPath *)idx inView:(UIView *)view
{
    //Job *job = [self.fetchedResultsController objectAtIndexPath:idx];
    //return job.objectID.URIRepresentation.absoluteString;
    // TODO: change me
    return @"changeme";
}

- (NSIndexPath *) indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view
{
    //NSURL *jobURL = [NSURL URLWithString:identifier];
    //NSManagedObjectID *jobID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:jobURL];
    //Job *job = (Job *)[self.managedObjectContext objectWithID:jobID];
    //return [_fetchedResultsController indexPathForObject:job];
    //TODO: change me
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

@end

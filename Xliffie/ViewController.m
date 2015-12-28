//
//  ViewController.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "ViewController.h"
#import "TranslationPair.h"
#import "TranslationTargetCell.h"

@interface ViewController ()

@property (weak) IBOutlet XMLOutlineView *outlineView;
@property (strong, nonatomic) Document *filteredDocument;
@property (strong, nonatomic) Document *mappingDocument;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentDidUndoOrRedo:)
                                                 name:NSUndoManagerDidUndoChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentDidUndoOrRedo:)
                                                 name:NSUndoManagerDidRedoChangeNotification
                                               object:nil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.outlineView.autosaveExpandedItems = YES;
    self.outlineView.xmlOutlineDelegate = self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Notification

- (void)documentDidUndoOrRedo:(NSNotification*)notification {
    NSUndoManager *manager = [notification object];
    if (manager == self.documentForDisplay.undoManager) {
        [self.outlineView reloadData];
    }
}

#pragma mark OutlineView

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    return [item isKindOfClass:[File class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item {
    if (!item) {
        return self.documentForDisplay.files.count;
    } else if ([item isKindOfClass:[File class]]) {
        return [(File*)item translations].count;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item {
    if (!item) {
        return self.documentForDisplay.files[index];
    } else if ([item isKindOfClass:[File class]]) {
        return [[(File*)item translations] objectAtIndex:index];
    }
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            return [(TranslationPair*)item sourceForDisplay];
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            return [(TranslationPair*)item target];
        } else if ([[tableColumn identifier] isEqualToString:@"note"]) {
            return [(TranslationPair*)item note];
        }
    } else if ([item isKindOfClass:[File class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            return [(File*)item original];
        }
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView
     setObjectValue:(id)object
     forTableColumn:(NSTableColumn *)tableColumn
             byItem:(id)item {
    
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            [(TranslationPair*)item setSource:object];
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            [(TranslationPair*)item setTarget:object];
        } else if ([[tableColumn identifier] isEqualToString:@"note"]) {
            [(TranslationPair*)item setNote:object];
        }
    }
    [self.document updateChangeCount:NSChangeDone];
}

- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(TranslationTargetCell*)cell
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"target"]) {
        
        if ([item isKindOfClass:[TranslationPair class]]) {
            TranslationPair *pair = (TranslationPair*)item;
            if (!pair.target || [pair.target isEqualToString:@""]) {
                cell.dotColor = [NSColor colorWithDeviceRed: 1 green: 0 blue: 0.369 alpha: 1];
            } else if ([pair.target isEqualToString:pair.source]) {
                cell.dotColor = [NSColor colorWithDeviceRed: 1 green: 0.675 blue: 0 alpha: 1];
            } else {
                cell.dotColor = nil;
            }
        } else {
            cell.dotColor = nil;
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"target"] && [item isKindOfClass:[TranslationPair class]]) {
        return YES;
    }
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSUInteger index = [self.outlineView selectedRow];
    id item = [self.outlineView itemAtRow:index];
    if ([item isKindOfClass:[TranslationPair class]]) {
        [self.delegate viewController:self didSelectedTranslation:item];
        [self.delegate viewController:self didSelectedFileChild:[item file]];
    } else {
        [self.delegate viewController:self didSelectedTranslation:nil];
        [self.delegate viewController:self didSelectedFileChild:item];
    }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (!item) return nil;
    NSCell *cell = [tableColumn dataCell];
    NSString *value = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
    [cell setObjectValue:value];
    [cell setWraps:YES];
    return cell;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    
    NSTableColumn *firstColumn = [[self.outlineView tableColumns] firstObject];
    NSTableColumn *secondColumn = [[self.outlineView tableColumns] objectAtIndex:1];
    NSCell *cell = [firstColumn dataCell];
    [cell setWraps:YES];
    
    if ([item isKindOfClass:[File class]]) {
        [cell setObjectValue:[item original]];
        return [cell cellSizeForBounds:CGRectMake(0, 0, [firstColumn width], CGFLOAT_MAX)].height;
    }
    
    [cell setObjectValue:[item source]];
    CGFloat sourceHeight = [cell cellSizeForBounds:CGRectMake(0, 0, [firstColumn width], CGFLOAT_MAX)].height;
    [cell setObjectValue:[item target]];
    CGFloat targetHeight = [cell cellSizeForBounds:CGRectMake(0, 0, [secondColumn width], CGFLOAT_MAX)].height;
    return MAX(sourceHeight, targetHeight);
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification {
    [self.outlineView reloadData];
}

#pragma mark checking

- (void)xmlOutlineView:(id)sender didEndEditingRow:(NSUInteger)row proposedString:(NSString*)proposed callback:(void (^)(BOOL))callback {
    TranslationPair *pair = [self.outlineView itemAtRow:row];
    NSArray *warnings = [pair formatWarningsForProposedTranslation:proposed];
    if ([warnings count]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Apply it anyway",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
        [alert setMessageText:NSLocalizedString(@"Maybe you've made a mistake?",nil)];
        [alert setInformativeText:[warnings componentsJoinedByString:@"\n"]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                callback(YES);
            } else {
                callback(NO);
            }
        }];
    } else {
        callback(YES);
    }
}

#pragma mark Document

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)setDocument:(Document *)document {
    _document = document;
    [self applyMapLanguage:self.mapLanguage];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (Document*)documentForDisplay {
    if (self.filteredDocument) {
        return self.filteredDocument;
    }
    return self.document;
}

#pragma mark Search

- (void)setSearchFilter:(NSString *)searchFilter {
    _searchFilter = searchFilter;
    if (!_searchFilter.length) {
        self.filteredDocument = nil;
    } else {
        self.filteredDocument = [self.document filteredDocumentWithSearchFilter:searchFilter];
    }
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (BOOL)isTranslationSelected:(TranslationPair*)translation {
    NSIndexSet *selectedIndexs = [self.outlineView selectedRowIndexes];
    __block BOOL isSelected = NO;
    [selectedIndexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        TranslationPair *thisTranslation = [self.outlineView itemAtRow:idx];
        if ([thisTranslation isEqualTo:translation]) {
            isSelected = YES;
            *stop = YES;
        }
    }];
    return isSelected;
}

#pragma mark mapping language

- (void)setMapLanguage:(NSString *)mapLanguage {
    if ([_mapLanguage isEqualToString:mapLanguage]) {
        return;
    }
    _mapLanguage = mapLanguage;
    [self applyMapLanguage:mapLanguage];
}

- (void)applyMapLanguage:(NSString*)mapLanguage {
    for (File *file in self.document.files) {
        File *alternativeFile = [self.delegate viewController:self
                                       alternativeFileForFile:file
                                                 withLanguage:mapLanguage];
        [file setSourceMapFile:alternativeFile];
    }
    [self.outlineView reloadData];
}

@end

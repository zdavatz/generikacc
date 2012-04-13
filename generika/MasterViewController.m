//
//  MasterViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import "JSONKit.h"
#import "AFJSONRequestOperation.h"

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "WebViewController.h"

@implementation MasterViewController

@synthesize resultText, resultImage;
@synthesize detailViewController = _detailViewController;

- (void)loadView
{
  [super loadView];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _tableView = [[UITableView alloc] initWithFrame:screenBounds];
  _tableView.delegate = self;
  _tableView.dataSource = self;	
  [self.view addSubview:_tableView];
  _objects = [[NSMutableArray alloc] init];

  // default
  NSDictionary *product  = [NSDictionary dictionaryWithObjectsAndKeys:
    @"39354",    @"reg",
    @"01" ,      @"seq", 
    @"020",      @"pack",
    @"Bricanyl", @"name",
    @"100 ml" ,  @"size",
    @"6.80" ,    @"price",
    @"B" ,       @"category",
    @"k.A.",     @"deduction",
    @"7680317060176", @"ean",
    nil];
  [_objects addObject:product];
}

- (void)dealloc
{
  _objects = nil;
  _tableView = nil;
  _nameLabel      = nil;
  _sizeLabel      = nil;
  _priceLabel     = nil;
  _deductionLabel = nil;
  _categoryLabel  = nil;
  _eanLabel       = nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem = self.editButtonItem;

  UIBarButtonItem *scanButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self
                                                                              action:@selector(scanButtonTapped:)];
  //UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
  self.navigationItem.rightBarButtonItem = scanButton;
  self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

  //UIButton *btn = [[UIBarButton alloc] buttonWithType:UIButtonTypeRoundedRect];
  //btn.frame = CGRectMake(10, 200, 300, 30);
  //[btn setTitle:@"scan" forState:UIControlStateNormal];
  //[btn addTarget:self action:@selector(scanButtonTapped:)forControlEvents:UIControlEventTouchDown];
  //[self.view addSubview:btn];
  [self openCamera];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated {
  NSIndexPath* selection = [_tableView indexPathForSelectedRow];
  if (selection) {
    [_tableView deselectRowAtIndexPath:selection animated:YES];
  }
  [_tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
  [_tableView flashScrollIndicators];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)insertNewObject:(id)sender
{
  if (!_objects) {
    _objects = [[NSMutableArray alloc] init];
  }
  [_objects insertObject:[NSDate date] atIndex:0];
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)scanButtonTapped:(UIButton*)button
{
  [self openCamera];
}


- (void)imagePickerController:(UIImagePickerController*)reader
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  id<NSFastEnumeration> results =
  [info objectForKey: ZBarReaderControllerResults];
  ZBarSymbol *symbol = nil;
  for (symbol in results) {
    break;
  }
  resultText.text = symbol.data;
  //resultImage.image = [info objectForKey: UIImagePickerControllerOriginalImage];
  //DLog(@"image = %@", resultImage.image);
  DLog(@"text: %@", symbol.data);
  NSString *ean = [NSString stringWithString:symbol.data];

  //http://ch.oddb.org/de/gcc/api_search/ean/7680317060176
  /* Stub
  NSDictionary *product  = [NSDictionary dictionaryWithObjectsAndKeys:
    @"39354",     @"reg",
    @"01," ,      @"seq", 
    @"020,",      @"pack",
    @"Bricanyl,", @"name",
    @"100 ml," ,  @"size",
    @"6.80," ,    @"price",
    @"B," ,       @"category",
    @"k.A.",      @"deduction",
    nil];
  DLog(@"%@", [product JSONString]);
  [self didFinishPicking:[product JSONData]];
  (*/
  NSString *searchURL = [NSString stringWithFormat:@"%@/%@", @"http://ch.oddb.org/de/mobile/api_search/ean", ean];
  NSURL *productSearch = [NSURL URLWithString:searchURL];
  DLog(@"url[productSearch]: %@", productSearch);
  NSURLRequest *request = [NSURLRequest requestWithURL:productSearch];
  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
      //NSLog(@"json: %@", JSON);
      [self didFinishPicking:JSON withEan:ean];
    }
    failure:nil];
  [operation start];
  // open oddb.org
  [self openCompareSearchByEan:ean];
  [reader dismissModalViewControllerAnimated: YES];
}

- (void)didFinishPicking:(id)json withEan:(NSString*)ean
{
  _productName = [json valueForKeyPath:@"name"];
  _productSize = [json valueForKeyPath:@"size"];
  DLog(@"name: %@", _productName);
  DLog(@"size: %@", _productSize);

  NSString *category = [[json valueForKeyPath:@"category"] stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
  NSDictionary *product = [NSDictionary dictionaryWithObjectsAndKeys:
    [json valueForKeyPath:@"reg"],       @"reg",
    [json valueForKeyPath:@"seq"],       @"seq",
    [json valueForKeyPath:@"pack"],      @"pack",
    [json valueForKeyPath:@"name"],      @"name",
    [json valueForKeyPath:@"size"],      @"size",
    [json valueForKeyPath:@"price"],     @"price",
    [json valueForKeyPath:@"deduction"], @"deduction",
    category, @"category",
    ean, @"ean",
    nil];
  [_objects addObject:product];
  DLog(@"objects: %@", _objects);
  // TODO store json
  //DLog(@"json: %@", [[product JSONString] class]);
  //DLog(@"json class: %@", [product JSONString]);
  /*
  NSString* emptyText = [json text];
  NSError* error;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  if([paths count] > 0){
    NSString* dirPath = [paths objectAtIndex:0];
    NSString* path = [dirPath stringByAppendingPathComponent:@"products.json"];
    BOOL result = [emptyText writeToFile:path
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:&error];
  }
  */
  DLog(@"save: %@", NSHomeDirectory());
  DLog(@"json: %@", json);
  NSString *message = [NSString stringWithFormat:@"%@, %@\n%@",
                        [product objectForKey:@"name"],
                        [product objectForKey:@"size"],
                        [product objectForKey:@"price"]];
  UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Detected" 
                                                 message:message
                                                delegate:self 
                                       cancelButtonTitle:@"OK" 
                                       otherButtonTitles:nil];
  [alert show];
}

-(void)openCamera
{
  ZBarReaderViewController *reader = [ZBarReaderViewController new];
  reader.readerDelegate = self;
  reader.supportedOrientationsMask = ZBarOrientationMaskAll;

  ZBarImageScanner *scanner = reader.scanner;
  // TODO: (optional) additional reader configuration here

  [scanner setSymbology:ZBAR_I25
                 config:ZBAR_CFG_ENABLE
                     to:0];
  [self presentModalViewController:reader
                          animated:YES];
  //[reader release];
}

- (void)openCompareSearchByEan:(NSString*)ean
{
  NSString *webURL = [NSString stringWithFormat:@"%@/%@", @"http://ch.oddb.org/de/mobile/compare/ean13", ean];
  NSURL *compareSearch = [NSURL URLWithString:webURL];
  DLog(@"url[compareSearch]: %@", compareSearch);
  browser = [[WebViewController alloc] init];
  [browser loadURL:compareSearch];
  [self.navigationController pushViewController: browser
                                       animated: YES];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  DLog(@"objects count: %d", _objects.count);
  return _objects.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	//NSDictionary *product = [_objects objectAtIndex:indexPath.row];
	return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  CGRect cellFrame = CGRectMake(0, 0, tableView.frame.size.width, 100);
  UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:cellFrame
                                                 reuseIdentifier:cellIdentifier];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  NSDictionary *product = [_objects objectAtIndex:indexPath.row];
  //DLog(@"product %@", product);

  UIView *productView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, cell.frame.size.width, cell.frame.size.height)];
  [cell.contentView addSubview:productView];

  // name
  _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 5.0, 180.0, 30.0)];
  _nameLabel.font = [UIFont boldSystemFontOfSize:15.0];
  _nameLabel.textAlignment = UITextAlignmentLeft;
  _nameLabel.textColor = [UIColor blackColor];
  _nameLabel.text = [NSString stringWithString:[product objectForKey:@"name"]];
  [cell.contentView addSubview:_nameLabel];
  // size
  CGSize nameSize = [[_nameLabel text] sizeWithFont:[_nameLabel font]];
  DLog(@"nameSize = %f", nameSize.width);
  _sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(70 + nameSize.width + 3.0, 7.0, 100.0, 30.0)];
  _sizeLabel.font = [UIFont boldSystemFontOfSize:12.0];
  _sizeLabel.textAlignment = UITextAlignmentLeft;
  _sizeLabel.textColor = [UIColor blackColor];
  _sizeLabel.text = [NSString stringWithString:[product objectForKey:@"size"]];
  [cell.contentView addSubview:_sizeLabel];
  // price
  _priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 30.0, 60.0, 16.0)];
  _priceLabel.font = [UIFont systemFontOfSize:12.0];
  _priceLabel.textAlignment = UITextAlignmentLeft;
  _priceLabel.textColor = [UIColor grayColor];
  NSString *price = [NSString stringWithString:[product objectForKey:@"price"]];
  //DLog(@"price: %@", price);
  if (![price isEqualToString:@"k.A."]) {
    _priceLabel.text = price;
  }
  [cell.contentView addSubview:_priceLabel];
  // deduction
  _deductionLabel = [[UILabel alloc] initWithFrame:CGRectMake(120.0, 30.0, 60.0, 16.0)];
  _deductionLabel.font = [UIFont systemFontOfSize:12.0];
  _deductionLabel.textAlignment = UITextAlignmentLeft;
  _deductionLabel.textColor = [UIColor grayColor];
  NSString *deduction = [NSString stringWithString:[product objectForKey:@"deduction"]];
  //DLog(@"deduction: %@", deduction);
  if (![deduction isEqualToString:@"k.A."]) {
    _deductionLabel.text = deduction;
  }
  [cell.contentView addSubview:_deductionLabel];
  // category
  _categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(160.0, 30.0, 190.0, 16.0)];
  _categoryLabel.font = [UIFont systemFontOfSize:12.0];
  _categoryLabel.textAlignment = UITextAlignmentLeft;
  _categoryLabel.textColor = [UIColor grayColor];
  _categoryLabel.text = [NSString stringWithString:[product objectForKey:@"category"]];
  [cell.contentView addSubview:_categoryLabel];
  // ean
  _eanLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 45.0, 260.0, 16.0)];
  _eanLabel.font = [UIFont systemFontOfSize:12.0];
  _eanLabel.textAlignment = UITextAlignmentLeft;
  _eanLabel.textColor = [UIColor grayColor];
  _eanLabel.text = [NSString stringWithString:[product objectForKey:@"ean"]];
  [cell.contentView addSubview:_eanLabel];

  DLog(@"cell %@", cell);
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Return NO if you do not want the specified item to be editable.
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [_objects removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
  }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  //self.detailViewController.detailItem = object;
  // open browser
  NSDictionary *object = [_objects objectAtIndex:indexPath.row];
  [self openCompareSearchByEan:[NSString stringWithString:[object objectForKey:@"ean"]]];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"showDetail"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSDate *object = [_objects objectAtIndex:indexPath.row];
    [[segue destinationViewController] setDetailItem:object];
  }
}
*/

@end



typedef enum {
    GPUIMAGE_SATURATION,
    GPUIMAGE_CONTRAST,
    GPUIMAGE_BRIGHTNESS,
    GPUIMAGE_LEVELS,
    GPUIMAGE_EXPOSURE,
    GPUIMAGE_RGB,
    GPUIMAGE_HUE,
    GPUIMAGE_WHITEBALANCE,
    GPUIMAGE_MONOCHROME,
    GPUIMAGE_SHARPEN,
    GPUIMAGE_GAMMA,
    GPUIMAGE_TONECURVE,
    GPUIMAGE_HIGHLIGHTSHADOW,
    GPUIMAGE_HAZE,
    GPUIMAGE_LUMINOSITY,
    GPUIMAGE_THRESHOLD,
    GPUIMAGE_ADAPTIVETHRESHOLD,
    GPUIMAGE_AVERAGELUMINANCETHRESHOLD,
    GPUIMAGE_TRANSFORM3D,
    GPUIMAGE_COLORINVERT,
    GPUIMAGE_GRAYSCALE,
    GPUIMAGE_SEPIA,
    GPUIMAGE_PIXELLATE,
    GPUIMAGE_POLARPIXELLATE,
    GPUIMAGE_PIXELLATE_POSITION,
    GPUIMAGE_POLKADOT,
    GPUIMAGE_HALFTONE,
    GPUIMAGE_CROSSHATCH,
    GPUIMAGE_CANNYEDGEDETECTION,
    GPUIMAGE_THRESHOLDEDGEDETECTION,
    GPUIMAGE_XYGRADIENT,
    GPUIMAGE_BUFFER,
    GPUIMAGE_SKETCH,
    GPUIMAGE_THRESHOLDSKETCH,
    GPUIMAGE_TOON,
    GPUIMAGE_SMOOTHTOON,
    GPUIMAGE_TILTSHIFT,
    GPUIMAGE_CGA,
    GPUIMAGE_EMBOSS,
    GPUIMAGE_LAPLACIAN,
    GPUIMAGE_POSTERIZE,
    GPUIMAGE_SWIRL,
    GPUIMAGE_BULGE,
    GPUIMAGE_PINCH,
    GPUIMAGE_STRETCH,
    GPUIMAGE_DILATION,
    GPUIMAGE_EROSION,
    GPUIMAGE_LOCALBINARYPATTERN,
    GPUIMAGE_VIGNETTE,
    GPUIMAGE_GAUSSIAN,
    GPUIMAGE_MOTIONBLUR,
    GPUIMAGE_ZOOMBLUR,
    GPUIMAGE_GAUSSIAN_SELECTIVE,
    GPUIMAGE_GAUSSIAN_POSITION,
    alpha54,
} GPUImageShowcaseFilterType;



#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

typedef void (^SDSenderBlock)(id sender);

@class SDDrawingViewController;

@protocol SDDrawingViewControllerDelegate <NSObject>

- (void)viewControllerDidSaveDrawing:(SDDrawingViewController*)viewController;
- (void)viewControllerDidCancelDrawing:(SDDrawingViewController*)viewController;
- (void)viewControllerDidDeleteDrawing:(SDDrawingViewController*)viewController;

@end

@interface SDDrawingViewController : UIViewController <UIGestureRecognizerDelegate>
{
    CGPoint dragOfficialChange;
    CGFloat rotationOfficialChange;
    CGFloat scalersOfficialChange;
    int moverViewButtonActive;
    BOOL moverViewActive;
    GPUImageShowcaseFilterType filterType;
    CGRect myPickerCropRect;
    // GPUImageOutput *filter;
    // GPUImageFilter *filter;
}
#pragma mark - IBOutlets

//these are public so they can be accessed via the drawingViewCustomization block property on SDDrawingsViewController
//- (IBAction)myRezandFilterButton:(UIBarButtonItem *)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *uiUndoButton;
@property (strong, nonatomic) UIImage *scaleHolderImage;
@property (strong, nonatomic) UIImage *curPreFilteredImage;
@property (strong, nonatomic) IBOutlet UIButton *titleButton;
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (weak, nonatomic) IBOutlet UIView *sliderFxSubView;
@property (weak, nonatomic) IBOutlet UIView *moverView;
@property (weak, nonatomic) IBOutlet UIButton *scaleButtonUiLook;
@property (weak, nonatomic) IBOutlet UIButton *positionButtonUILook;
@property (weak, nonatomic) IBOutlet UIButton *rotateButtonUILook;

@property (weak, nonatomic) IBOutlet UILabel *moveViewLabel;
- (IBAction)scaleButtonPressed:(UIButton *)sender;
- (IBAction)positionButtonTapped:(UIButton *)sender;
- (IBAction)rotateButtonPressed:(UIButton *)sender;
- (IBAction)cancelMoveViewPressed:(UIButton *)sender;
- (IBAction)doneMoverViewButtonPressed:(UIButton *)sender;

- (IBAction)rotationGest:(UIRotationGestureRecognizer *)sender;
- (IBAction)pinchGest:(UIPinchGestureRecognizer *)sender;
- (IBAction) dragging: (UIPanGestureRecognizer*) p;

- (IBAction)sliderFxDoneButton:(UIButton *)sender;

- (IBAction)filterSettingsSlider:(UISlider *)sender forEvent:(UIEvent *)event;


- (IBAction)myRedoButtonTapped:(UIBarButtonItem *)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *drawToolButton;

@property (weak, nonatomic) IBOutlet UISlider *filterSettingsSlider;

#pragma mark - Properties

@property (weak) id<SDDrawingViewControllerDelegate> delegate;
@property (copy) NSString *drawingID;

//optional - block called after viewDidLoad for customization of the drawing view
//sender will be an SDDrawingViewController where you can access public properties/methods
@property (copy) SDSenderBlock customization;

//optional - block called after initializing the list of SDDrawingTools
//sender will be an NSMutableArray of SDDrawingTool subclasses
@property (copy) SDSenderBlock toolListCustomization;

@end
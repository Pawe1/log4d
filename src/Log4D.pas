unit Log4D;

{
  Logging for Delphi.
  Based on log4j Java package from Apache
  (http://jakarta.apache.org/log4j/docs/index.html).

  Written by Keith Wood (kbwood@compuserve.com).
  Version 1.0 - 29 April 2001.
}

interface

uses
  Classes, Windows,                
{$IFNDEF VER120}  { Not Delphi 4 }
  Contnrs,
{$ENDIF}
  SysUtils;

const
  { Default pattern string for log output.
    Shows the application supplied message. }
  DefaultPattern = '%m%n';
  { A conversion pattern equivalent to the TTCC layout.
    Shows runtime, thread, priority, category, NDC, and message. }
  TTCCPattern    = '%r [%t] %p %c %x - %m%n';

  { Common prefix for option names in an initialisation file.
    Note that the search for all option names is case sensitive. }
  KeyPrefix          = 'log4d';
  { Specify the additivity of a category's appenders. }
  AdditiveKey        = KeyPrefix + '.additive.';
  { Define a named appender. }
  AppenderKey        = KeyPrefix + '.appender.';
  { Nominate a factory to use to generate categories.
    This factory must have been registered with RegisterCategoryFactory.
    If none is specified, then the default factory is used. }
  CategoryFactoryKey = KeyPrefix + '.categoryFactory';
  { Define a new category, and set its logging level and appenders. }
  CategoryKey        = KeyPrefix + '.category.';
  { Defining this value as true makes log4d print internal debug
    statements to debug output. }
  DebugKey           = KeyPrefix + '.debug';
  { Setting this property to DEBUG, INFO, WARN, ERROR or FATAL is equivalent
    to calling the TLogHierarchy.Disable method with the corresponding priority.
    This globally disables that level (and below) of logging.

    If both log4d.disableOverride and a log4d.disable options are present, then
    log4d.disableOverride, as the name indicates, overrides any former options. }
  DisableKey         = KeyPrefix + '.disable';
  { Setting this property to 'true' overrides the effects of all methods
    TLogHierarchy.Disable, TLogHierarchy.DisableAll, TLogHierarchy.DisableDebug
    and TLogHierarchy.DisableInfo. Thus enabling normal evaluation of logging
    requests, i.e. according to the Basic Selection Rule.

    If both log4d.disableOverride and a log4d.disable options are present, then
    log4d.disableOverride, as the name indicates, overrides any former options. }
  DisableOverrideKey = KeyPrefix + '.disableOverride';
  { Specify the error handler to be used with an appender. }
  ErrorHandlerKey    = '.errorHandler';
  { Specify the filters to be used with an appender. }
  FilterKey          = '.filter';
  { Specify the layout to be used with an appender. }
  LayoutKey          = '.layout';
  { Associate an object renderer with the class to be rendered. }
  RendererKey        = KeyPrefix + '.renderer.';
  { Set the logging level and appenders for the root. }
  RootCategoryKey    = KeyPrefix + '.rootCategory';

  { Special priority value signifying inherited behaviour. }
  InheritedPriority  = 'INHERITED';

  { Accept option for TLog*Filter. }
  AcceptMatchOpt = 'acceptOnMatch';
  { Appending option for TLogFileAppender. }
  AppendOpt      = 'append';
  { Common date format option for layouts. }
  DateFormatOpt  = 'dateFormat';
  { File name option for TLogFileAppender. }
  FileNameOpt    = 'fileName';
  { Match string option for TLog*Filter. }
  MatchOpt       = 'match';
  { Pattern option for TLogPatternLayout. }
  PatternOpt     = 'pattern';

type
{$IFDEF VER120}  { Delphi 4 }
  TClassList  = TList;
  TObjectList = TList;
{$ENDIF}

  { Log-specific exceptions. }
  ELogException = class(Exception);

  { Allow for initialisation of a dynamically created object. }
  ILogDynamicCreate = interface(IUnknown)
    ['{287DAA34-3A9F-45C6-9417-1B0D4DFAC86C}']
    procedure Init;
  end;

  { Get/set arbitrary options on an object. }
  ILogOptionHandler = interface(ILogDynamicCreate)
    ['{AC1C0E30-2DBF-4C55-9C2E-9A0F1A3E4F58}']
    function GetOption(const Name: string): string;
    procedure SetOption(const Name, Value: string);
    property Options[const Name: string]: string read GetOption write SetOption;
  end;

  { Base class for handling options. }
  TLogOptionHandler = class(TInterfacedObject, ILogOptionHandler)
  private
    FOptions: TStringList;
  protected
    function GetOption(const Name: string): string; virtual;
    procedure SetOption(const Name, Value: string); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property Options[const Name: string]: string read GetOption write SetOption;
    procedure Init; virtual;
  end;

{ Priorities ------------------------------------------------------------------}

  { Levels of messages for logging.
    The Level property identifies increasing severity of messages.
    All those above or equal to a particular setting are logged. }
  TLogPriority = class(TObject)
  private
    FLevel: Integer;
    FName: string;
  public
    constructor Create(Name: string; Level: Integer);
    property Level: Integer read FLevel;
    property Name: string read FName;
    function IsGreaterOrEqual(Priority: TLogPriority): Boolean;
  end;

var
  { Standard priorities are automatically created (in increasing severity):
    Debug, Info, Warn, Error, Fatal. }
  Debug: TLogPriority;
  Info:  TLogPriority;
  Warn:  TLogPriority;
  Error: TLogPriority;
  Fatal: TLogPriority;

{ Return a list of all the priorities defined. }
function GetAllPriorities: TObjectList;

{ Retrieve a priority object given its level. }
function GetPriority(Level: Integer): TLogPriority; overload;
{ Retrieve a priority object given its name. }
function GetPriority(Name: string): TLogPriority; overload;

{ NDC -------------------------------------------------------------------------}

type
  { Keep track of the nested diagnostic context (NDC). }
  TLogNDC = class(TObject)
  public
    class procedure Clear;
    class function Context: string;
    class procedure Pop;
    class procedure Push(Context: string);
  end;

{ Events ----------------------------------------------------------------------}

  TLogCategory = class;

  { An event to be logged. }
  TLogEvent = class(TObject)
  private
    FCategory: TLogCategory;
    FError: Exception;
    FMessage: string;
    FPriority: TLogPriority;
    FTimeStamp: TDateTime;
    function GetElapsedTime: LongInt;
    function GetErrorMessage: string;
    function GetNDC: string;
    function GetThreadId: LongInt;
  public
    constructor Create(Category: TLogCategory; Priority: TLogPriority;
      Message: string; Err: Exception); overload;
    constructor Create(Category: TLogCategory; Priority: TLogPriority;
      Message: TObject; Err: Exception); overload;
    property Category: TLogCategory read FCategory;
    property ElapsedTime: LongInt read GetElapsedTime;
    property Error: Exception read FError;
    property ErrorMessage: string read GetErrorMessage;
    property Message: string read FMessage;
    property NDC: string read GetNDC;
    property Priority: TLogPriority read FPriority;
    property ThreadId: LongInt read GetThreadId;
    property TimeStamp: TDateTime read FTimeStamp;
  end;

{ Category factory ------------------------------------------------------------}

  { Factory for creating categories. }
  ILogCategoryFactory = interface(IUnknown)
    ['{3B9A05AF-91F7-450D-9942-B8393ED1D52D}']
    function MakeNewCategoryInstance(Name: string): TLogCategory;
  end;

  { Default implementation of a category factory. }
  TLogDefaultCategoryFactory = class(TInterfacedObject, ILogCategoryFactory)
  public
    function MakeNewCategoryInstance(Name: string): TLogCategory;
  end;

{ Categories ------------------------------------------------------------------}

  ILogAppender = interface;
  ILogRenderer = interface;
  TLogHierarchy = class;

  { This is the central class in the Log4D package. One of the distinctive
    features of Log4D is hierarchical categories and their evaluation. }
  TLogCategory = class(TLogOptionHandler, ILogOptionHandler)
  private
    FAdditive: Boolean;
    FAppenders: TInterfaceList;
    FHierarchy: TLogHierarchy;
    FName: string;
    FParent: TLogCategory;
    FPriority: TLogPriority;
  protected
    FCriticalCategory: TRTLCriticalSection;
    procedure CallAppenders(Event: TLogEvent);
    procedure CloseAllAppenders;
    function CountAppenders: Integer;
    procedure DoLog(Priority: TLogPriority; Message: string; Err: Exception);
      overload; virtual;
    procedure DoLog(Priority: TLogPriority; Message: TObject; Err: Exception);
      overload; virtual;
    function GetPriority: TLogPriority; virtual;
  public
    constructor Create(Name: string); reintroduce;
    destructor Destroy; override;
    property Additive: Boolean read FAdditive write FAdditive;
    property Appenders: TInterfaceList read FAppenders;
    property Hierarchy: TLogHierarchy read FHierarchy write FHierarchy;
    property Name: string read FName;
    property Parent: TLogCategory read FParent;
    property Priority: TLogPriority read GetPriority write FPriority;
    procedure AddAppender(Appender: ILogAppender);
    procedure Debug(Message: string; Err: Exception = nil); overload; virtual;
    procedure Debug(Message: TObject; Err: Exception = nil); overload; virtual;
    procedure Error(Message: string; Err: Exception = nil); overload; virtual;
    procedure Error(Message: TObject; Err: Exception = nil); overload; virtual;
    procedure Fatal(Message: string; Err: Exception = nil); overload; virtual;
    procedure Fatal(Message: TObject; Err: Exception = nil); overload; virtual;
    class function GetInstance(Name: string;
      Factory: ILogCategoryFactory = nil): TLogCategory;
    procedure Info(Message: string; Err: Exception = nil); overload; virtual;
    procedure Info(Message: TObject; Err: Exception = nil); overload; virtual;
    function IsDebugEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsPriorityEnabled(Priority: TLogPriority): Boolean;
    function IsWarnEnabled: Boolean;
    procedure LockCategory;
    procedure Log(Priority: TLogPriority; Message: string;
      Err: Exception = nil); overload;
    procedure Log(Priority: TLogPriority; Message: TObject;
      Err: Exception = nil); overload;
    procedure RemoveAllAppenders;
    procedure RemoveAppender(Appender: ILogAppender);
    procedure UnlockCategory;
    procedure Warn(Message: string; Err: Exception = nil); overload; virtual;
    procedure Warn(Message: TObject; Err: Exception = nil); overload; virtual;
  end;

  { The specialised root category - cannot have a nil priority. }
  TLogRoot = class(TLogCategory)
  private
    procedure SetPriority(Priority: TLogPriority);
  public
    constructor Create(Priority: TLogPriority);
    property Priority: TLogPriority read GetPriority write SetPriority;
  end;

  { Specialised category for internal logging. }
  TLogLog = class(TLogCategory)
  private
    FInternalDebugging: Boolean;
  protected
    procedure DoLog(Priority: TLogPriority; Message: string; Err: Exception);
      override;
    procedure DoLog(Priority: TLogPriority; Message: TObject; Err: Exception);
      override;
  public
    constructor Create;
    property InternalDebugging: Boolean read FInternalDebugging
      write FInternalDebugging;
  end;

{ Hierarchy -------------------------------------------------------------------}

  { This class is specialized in retreiving categories by name and
    also maintaining the category hierarchy.

    The casual user should not have to deal with this class directly.

    The structure of the category hierachy is maintained by the GetInstance
    method. The hierarchy is such that children link to their parent but
    parents do not have any pointers to their children. Moreover, categories
    can be instantiated in any order, in particular decendant before ancestor.

    In case a decendant is created before a particular ancestor, then it creates
    an empty node for the ancestor and adds itself to it. Other decendants
    of the same ancestor add themselves to the previously created node. }
  TLogHierarchy = class(TObject)
  private
    FCategories: TStringList;
    FDisable: Integer;
    FRenderedClasses: TClassList;
    FRenderers: TInterfaceList;
    FRoot: TLogCategory;
    procedure UpdateParent(Cat: TLogCategory);
  protected
    FCriticalHierarchy: TRTLCriticalSection;
  public
    constructor Create(Root: TLogCategory);
    destructor Destroy; override;
    property Root: TLogCategory read FRoot;
    procedure AddRenderer(RenderedClass: TClass; Renderer: ILogRenderer);
    procedure Clear;
    procedure Disable(Priority: TLogPriority);
    procedure DisableAll;
    procedure DisableDebug;
    procedure DisableInfo;
    procedure EnableAll;
    function Exists(Name: string): TLogCategory;
    procedure GetCurrentCategories(List: TStringList);
    function GetInstance(Name: string; Factory: ILogCategoryFactory = nil):
      TLogCategory;
    function GetRenderer(RenderedClass: TClass): ILogRenderer;
    function IsDisabled(Level: Integer): Boolean;
    procedure OverrideDisable;
    procedure ResetConfiguration;
    procedure Shutdown;
  end;

{ Layouts ---------------------------------------------------------------------}

  { Functional requirements for a layout. }
  ILogLayout = interface(ILogOptionHandler)
    ['{87FDD680-96D7-45A0-A135-CB88ABAD5519}']
    function Format(Event: TLogEvent): string;
    function GetContentType: string;
    function GetFooter: string;
    function GetHeader: string;
    function IgnoresException: Boolean;
    property ContentType: string read GetContentType;
    property Footer: string read GetFooter;
    property Header: string read GetHeader;
  end;

  { Abstract base for layouts.
    Subclasses must at least override Format. }
  TLogCustomLayout = class(TLogOptionHandler, ILogDynamicCreate,
    ILogOptionHandler, ILogLayout)
  private
    FDateFormat: string;
  protected
    property DateFormat: string read FDateFormat write FDateFormat;
    function GetContentType: string; virtual;
    function GetHeader: string; virtual;
    function GetFooter: string; virtual;
    procedure SetOption(const Name, Value: string); override;
  public
    property ContentType: string read GetContentType;
    property Footer: string read GetFooter;
    property Header: string read GetHeader;
    function Format(Event: TLogEvent): string; virtual; abstract;
    function IgnoresException: Boolean; virtual;
    procedure Init; override;
  end;

  { Basic implementation of a layout. }
  TLogSimpleLayout = class(TLogCustomLayout)
  public
    function Format(Event: TLogEvent): string; override;
  end;

  { This layout outputs events in a HTML table. }
  TLogHTMLLayout = class(TLogCustomLayout)
  protected
    function GetContentType: string; override;
    function GetFooter: string; override;
    function GetHeader: string; override;
  public
    function Format(Event: TLogEvent): string; override;
    function IgnoresException: Boolean; override;
  end;

  { Layout based on specified pattern. }
  TLogPatternLayout = class(TLogCustomLayout)
  private
    FPattern: string;
    FPatternParts: TStringList;
    procedure SetPattern(Pattern: string);
  protected
    procedure SetOption(const Name, Value: string); override;
  public
    constructor Create(Pattern: string = DefaultPattern); reintroduce;
    destructor Destroy; override;
    property Pattern: string read FPattern write SetPattern;
    function Format(Event: TLogEvent): string; override;
    procedure Init; override;
  end;

{ Renderers -------------------------------------------------------------------}

  { Renderers transform an object into a string message for display. }
  ILogRenderer = interface(ILogOptionHandler)
    ['{169B03C6-E2C7-4F62-AD19-17408AB30681}']
    function Render(Message: TObject): string;
  end;

  { Abstract base class for renderers - handles basic option setting.
    Subclasses must at least override Render. }
  TLogCustomRenderer = class(TLogOptionHandler, ILogDynamicCreate,
    ILogOptionHandler, ILogRenderer)
  public
    function Render(Message: TObject): string; virtual; abstract;
  end;

{ ErrorHandler ----------------------------------------------------------------}

  { Appenders may delegate their error handling to ErrorHandlers.

    Error handling is a particularly tedious to get right because by
    definition errors are hard to predict and to reproduce. }
  ILogErrorHandler = interface(ILogOptionHandler)
    ['{8C82B343-3AD5-4188-A385-DA424BC75BC0}']
    { This method prints the error message passed as a parameter. }
    procedure Error(Message: string); overload;
    { This method should handle the error. Information about the error
      condition is passed a parameter. }
    procedure Error(Message: string; Err: Exception; ErrorCode: Integer);
      overload;
  end;

  { Abstract base class for error handlers - handles basic option setting.
    Subclasses must at least override Error. }
  TLogCustomErrorHandler = class(TLogOptionHandler, ILogDynamicCreate,
    ILogOptionHandler, ILogErrorHandler)
  public
    procedure Error(Message: string); overload; virtual; abstract;
    procedure Error(Message: string; Err: Exception; ErrorCode: Integer);
      overload; virtual; abstract;
  end;

  { Displays only the first error sent to it to debugging output. }
  TLogOnlyOnceErrorHandler = class(TLogCustomErrorHandler)
  private
    FSeenError: Boolean;
  public
    procedure Error(Message: string); overload; override;
    procedure Error(Message: string; Err: Exception; ErrorCode: Integer);
      overload; override;
  end;

{ Filters ---------------------------------------------------------------------}

  TLogFilterDecision = (fdDeny, fdNeutral, fdAccept);

  { Filters can control to a finer degree of detail which messages get logged. }
  ILogFilter = interface(ILogOptionHandler)
    ['{B28213D7-ACE2-4C44-B820-D9437D44F8DA}']
    function Decide(Event: TLogEvent): TLogFilterDecision;
  end;

  { Abstract base class for filters - handles basic option setting.
    Subclasses must at least override Decide. }
  TLogCustomFilter = class(TLogOptionHandler, ILogDynamicCreate,
    ILogOptionHandler, ILogFilter)
  private
    FAcceptOnMatch: Boolean;
  protected
    property AcceptOnMatch: Boolean read FAcceptOnMatch write FAcceptOnMatch;
    procedure SetOption(const Name, Value: string); override;
  public
    function Decide(Event: TLogEvent): TLogFilterDecision; virtual; abstract;
  end;

  { Filter by the message's priority. }
  TLogPriorityFilter = class(TLogCustomFilter)
  private
    FMatch: TLogPriority;
  protected
    procedure SetOption(const Name, Value: string); override;
  public
    constructor Create(Match: TLogPriority; AcceptOnMatch: Boolean = True);
      reintroduce;
    property AcceptOnMatch;
    property Match: TLogPriority read FMatch write FMatch;
    function Decide(Event: TLogEvent): TLogFilterDecision; override;
  end;

  { Filter by text within the message. }
  TLogStringFilter = class(TLogCustomFilter)
  private
    FMatch: string;
  protected
    procedure SetOption(const Name, Value: string); override;
  public
    constructor Create(Match: string; AcceptOnMatch: Boolean = True);
      reintroduce;
    property AcceptOnMatch;
    property Match: string read FMatch write FMatch;
    function Decide(Event: TLogEvent): TLogFilterDecision; override;
  end;

{ Appenders -------------------------------------------------------------------}

  { Implement this interface for your own strategies
    for printing log statements. }
  ILogAppender = interface(ILogOptionHandler)
    ['{E1A06EA7-34CA-4DA4-9A8A-C76CF34257AC}']
    procedure AddFilter(Filter: ILogFilter);
    procedure Append(Event: TLogEvent);
    procedure Close;
    function GetErrorHandler: ILogErrorHandler;
    function GetFilters: TInterfaceList;
    function GetLayout: ILogLayout;
    function GetName: string;
    procedure RemoveAllFilters;
    procedure RemoveFilter(Filter: ILogFilter);
    function RequiresLayout: Boolean;
    procedure SetErrorHandler(ErrorHandler: ILogErrorHandler);
    procedure SetLayout(Layout: ILogLayout);
    procedure SetName(Name: string);
    property ErrorHandler: ILogErrorHandler read GetErrorHandler
      write SetErrorHandler;
    property Filters: TInterfaceList read GetFilters;
    property Layout: ILogLayout read GetLayout write SetLayout;
    property Name: string read GetName write SetName;
  end;

  { Basic implementation of an appender for printing log statements.
    Subclasses should at least override DoAppend(string). }
  TLogCustomAppender = class(TLogOptionHandler, ILogDynamicCreate,
    ILogOptionHandler, ILogAppender)
  private
    FClosed: Boolean;
    FErrorHandler: ILogErrorHandler;
    FFilters: TInterfaceList;
    FLayout: ILogLayout;
    FName: string;
    function GetErrorHandler: ILogErrorHandler;
    function GetFilters: TInterfaceList;
    function GetLayout: ILogLayout;
    function GetName: string;
    procedure SetErrorHandler(ErrorHandler: ILogErrorHandler);
    procedure SetLayout(Layout: ILogLayout);
    procedure SetName(Name: string);
  protected
    FCriticalAppender: TRTLCriticalSection;
    function CheckEntryConditions: Boolean; virtual;
    function CheckFilters(Event: TLogEvent): Boolean; virtual;
    procedure DoAppend(Event: TLogEvent); overload; virtual;
    procedure DoAppend(Message: string); overload; virtual; abstract;
    procedure WriteFooter; virtual;
    procedure WriteHeader; virtual;
  public
    constructor Create(Name: string; Layout: ILogLayout = nil); reintroduce;
      virtual;
    destructor Destroy; override;
    property ErrorHandler: ILogErrorHandler read GetErrorHandler
      write SetErrorHandler;
    property Filters: TInterfaceList read GetFilters;
    property Layout: ILogLayout read GetLayout write SetLayout;
    property Name: string read GetName write SetName;
    procedure AddFilter(Filter: ILogFilter); virtual;
    procedure Append(Event: TLogEvent); virtual;
    procedure Close; virtual;
    procedure Init; override;
    procedure RemoveAllFilters; virtual;
    procedure RemoveFilter(Filter: ILogFilter); virtual;
    function RequiresLayout: Boolean; virtual;
  end;

  { Discard log messages. }
  TLogNullAppender = class(TLogCustomAppender)
  protected
    procedure DoAppend(Message: string); override;
  end;

  { Send log messages to debugging output. }
  TLogODSAppender = class(TLogCustomAppender)
  protected
    procedure DoAppend(Message: string); override;
  end;

  { Send log messages to a stream. }
  TLogStreamAppender = class(TLogCustomAppender)
  private
    FStream: TStream;
  protected
    procedure DoAppend(Message: string); override;
  public
    constructor Create(Name: string; Stream: TStream; Layout: ILogLayout = nil);
      reintroduce; virtual;
    destructor Destroy; override;
  end;

  { Send log messages to a file. }
  TLogFileAppender = class(TLogStreamAppender)
  private
    FAppend: Boolean;
    FFileName: TFileName;
  protected
    procedure SetOption(const Name, Value: string); override;
  public
    constructor Create(Name, FileName: string; Layout: ILogLayout = nil;
      Append: Boolean = True); reintroduce; virtual;
    property FileName: TFileName read FFileName;
    property OpenAppend: Boolean read FAppend;
  end;

{ Configurators ---------------------------------------------------------------}

  { Use this class to quickly configure the package. }
  TLogBasicConfigurator = class(TObject)
  private
    FRegistry: TStringList;
    FCategoryFactory: ILogCategoryFactory;
  protected
    { Used by subclasses to add a renderer
      to the hierarchy passed as parameter. }
    procedure AddRenderer(Hierarchy: TLogHierarchy;
      RenderedName, RendererName: string);
    function AppenderGet(Name: string): ILogAppender;
    procedure AppenderPut(Appender: ILogAppender);
    procedure SetGlobalProps(Hierarchy: TLogHierarchy;
      FactoryClassName, Debug, Disable, DisableOverride: string);
  public
    constructor Create;
    destructor Destroy; override;
    { Add appender to the root category. If no appender is provided,
      add a TLogODSAppender that uses TLogPatternLayout with the
      TTCCPattern and prints to debugging output for the root category. }
    class procedure Configure(Appender: ILogAppender = nil);
    { Reset the default hierarchy to its defaut. It is equivalent to calling
      Category.GetDefaultHierarchy.ResetConfiguration.
      See TLogHierarchy.ResetConfiguration for more details. }
    class procedure ResetConfiguration;
  end;

  { Extends BasicConfigurator to provide configuration from an external file.
    See DoConfigure for the expected format.

    It is sometimes useful to see how Log4D is reading configuration files.
    You can enable Log4D internal logging by defining the log4d.debug variable. }
  TLogPropertyConfigurator = class(TLogBasicConfigurator)
  protected
    procedure ConfigureRootCategory(Props: TStringList;
      Hierarchy: TLogHierarchy);
    procedure ParseAdditivityForCategory(Props: TStringList; Cat: TLogCategory);
    function ParseAppender(Props: TStringList; AppenderName: string):
      ILogAppender;
    procedure ParseCategoriesAndRenderers(Props: TStringList;
      Hierarchy: TLogHierarchy);
    procedure ParseCategory(Props: TStringList; Cat: TLogCategory;
      Value: string);
  public
    class procedure Configure(Filename: string); overload;
    class procedure Configure(Props: TStringList); overload;
    procedure DoConfigure(FileName: string; Hierarchy: TLogHierarchy);
      overload;
    procedure DoConfigure(Props: TStringList; Hierarchy: TLogHierarchy);
      overload;
  end;

{ Register a new appender class. }
procedure RegisterAppender(Appender: TClass);
{ Find an appender based on its class name and create a new instance of it. }
function FindAppender(ClassName: string): ILogAppender;

{ Register a new category factory class. }
procedure RegisterCategoryFactory(CategoryFactory: TClass);
{ Find a category factory based on its class name
  and create a new instance of it. }
function FindCategoryFactory(ClassName: string): ILogCategoryFactory;

{ Register a new error handler class. }
procedure RegisterErrorHandler(ErrorHandler: TClass);
{ Find an error handler based on its class name
  and create a new instance of it. }
function FindErrorHandler(ClassName: string): ILogErrorHandler;

{ Register a new filter class. }
procedure RegisterFilter(Filter: TClass);
{ Find a filter based on its class name and create a new instance of it. }
function FindFilter(ClassName: string): ILogFilter;

{ Register a new layout class. }
procedure RegisterLayout(Layout: TClass);
{ Find a layout based on its class name and create a new instance of it. }
function FindLayout(ClassName: string): ILogLayout;

{ Register a new class that can be rendered. }
procedure RegisterRendered(Rendered: TClass);
{ Find a rendered class based on its class name and return its class. }
function FindRendered(ClassName: string): TClass;

{ Register a new object renderer class. }
procedure RegisterRenderer(Renderer: TClass);
{ Find an object renderer based on its class name
  and create a new instance of it. }
function FindRenderer(ClassName: string): ILogRenderer;

{ Convert string value to a Boolean, with default. }
function StrToBool(Value: string; Default: Boolean): Boolean;

var
  { Default implementation of ILogCategoryFactory }
  DefaultCategoryFactory: TLogDefaultCategoryFactory;
  { The logging hierarchy }
  DefaultHierarchy: TLogHierarchy;
  { Internal package logging. }
  LogLog: TLogLog;

implementation

const
  CRLF = #13#10;
  MilliSecsPerDay = 24 * 60 * 60 * 1000;

resourcestring
  AppenderDefinedMsg      = 'Appender "%s" was already parsed';
  BadConfigFileMsg        = 'Couldn''t read configuration file "%s" - %s';
  CategoryFactoryMsg      = 'Setting category factory to "%s"';
  CategoryHdr             = 'Category';
  ClosedAppenderMsg       = 'Not allowed to write to a closed appender';
  EndAppenderMsg          = 'Parsed "%s" options';
  EndErrorHandlerMsg      = 'End of parsing for "%s" error handler';
  EndFiltersMsg           = 'End of parsing for "%s" filter';
  EndLayoutMsg            = 'End of parsing for "%s" layout';
  FinishedConfigMsg       = 'Finished configuring with %s';
  HandlingAdditivityMsg   = 'Handling %s="%s"';
  IgnoreConfigMsg         = 'Ignoring configuration file "%s"';
  InterfaceNotImplMsg     = '%s doesn''t implement %s';
  LayoutRequiredMsg       = 'Appender "%s" requires a layout';
  MessageHdr              = 'Message';
  NDCHdr                  = 'NDC';
  NilErrorHandlerMsg      = 'An appender cannot have a nil error handler';
  NilPriorityMsg          = 'The root can''t have a nil priority';
  NoAppendersMsg          = 'No appenders could be found for category "%s"';
  NoAppenderCreatedMsg    = 'Couldn''t create appender named "%s"';
  NoClassMsg              = 'Couldn''t find class %s';
  NoLayoutMsg             = 'No layout set for appender named "%s"';
  NoRenderedCreatedMsg    = 'Couldn''t find rendered class "%s"';
  NoRendererMsg           = 'No renderer found for class %s';
  NoRendererCreatedMsg    = 'Couldn''t create renderer "%s"';
  NoRootCategoryMsg       = 'Couldn''t find root category information. Is this OK?';
  OverrideDisableMsg      = 'Overriding disable';
  ParsingAppenderMsg      = 'Parsing appender named "%s"';
  ParsingCategoryMsg      = 'Parsing for category "%s" with value="%s"';
  ParsingErrorHandlderMsg = 'Parsing error handler options for "%s"';
  ParsingFiltersMsg       = 'Parsing filter options for "%s"';
  ParsingLayoutMsg        = 'Parsing layout options for "%s"';
  PleaseInitMsg           = 'Please initialize the Log4D system properly';
  PriorityHdr             = 'Priority';
  PriorityTokenMsg        = 'Priority token is "%s"';
  RendererMsg             = 'Rendering class: "%s", Rendered class: "%s"';
  SettingAdditivityMsg    = 'Setting additivity for "%s" to "%s"';
  SettingPriorityMsg      = 'Category "%s" set to priority "%s"';
  ThreadHdr               = 'Thread';
  TimeHdr                 = 'Time';
  ValueUnknownMsg         = 'Unknown';

var
  { Start time for the logging process - to compute elapsed time. }
  StartTime: TDateTime;

{ TLogOptionHandler -----------------------------------------------------------}

constructor TLogOptionHandler.Create;
begin
  inherited Create;
  Init;
end;

destructor TLogOptionHandler.Destroy;
begin
  FOptions.Free;
  inherited Destroy;
end;

{ Just return the saved option value. }
function TLogOptionHandler.GetOption(const Name: string): string;
begin
  Result := FOptions.Values[Name];
end;

procedure TLogOptionHandler.Init;
begin
  FOptions := TStringList.Create;
end;

{ Just save the option value. }
procedure TLogOptionHandler.SetOption(const Name, Value: string);
begin
  FOptions.Values[Name] := Value;
end;

{ TLogPriority ----------------------------------------------------------------}

var
  Priorities: TObjectList;

{ Accumulate a list (in descending order) of TLogPriority objects defined. }
procedure RegisterPriority(Priority: TLogPriority);
var
  Index: Integer;
begin
  if Priorities.IndexOf(Priority) > -1 then
    Exit;
  for Index := 0 to Priorities.Count - 1 do
    if TLogPriority(Priorities[Index]).Level < Priority.Level then
    begin
      Priorities.Insert(Index, Priority);
      Exit;
    end
    else if TLogPriority(Priorities[Index]).Level = Priority.Level then
    begin
{$IFDEF VER120}  { Delphi 4 }
      TObject(Priorities[Index]).Free;
{$ELSE}
      Priorities[Index].Free;
{$ENDIF}
      Priorities[Index] := Priority;
      Exit;
    end;
  Priorities.Add(Priority);
end;

{ Return all possible priorities as a list of TLogPriority objects in
  descending order. }
function GetAllPriorities: TObjectList;
begin
  Result := Priorities;
end;

{ Return a priority given its level, or nil if not found. }
function GetPriority(Level: Integer): TLogPriority;
var
  Index: Integer;
begin
  Result := nil;
  for Index := 0 to Priorities.Count - 1 do
    if TLogPriority(Priorities[Index]).Level = Level then
    begin
      Result := TLogPriority(Priorities[Index]);
      Break;
    end
    else if TLogPriority(Priorities[Index]).Level < Level then
      Break;
end;

{ Return a priority given its name, or nil if not found. }
function GetPriority(Name: string): TLogPriority;
var
  Index: Integer;
begin
  for Index := 0 to Priorities.Count - 1 do
    if TLogPriority(Priorities[Index]).Name = Name then
    begin
      Result := TLogPriority(Priorities[Index]);
      Exit;
    end;
  Result := nil;
end;

constructor TLogPriority.Create(Name: string; Level: Integer);
begin
  inherited Create;
  FName  := Name;
  FLevel := Level;
  RegisterPriority(Self);
end;

{ Returns True if this priority has a higher or equal priority
  than the priority passed as argument, False otherwise. }
function TLogPriority.IsGreaterOrEqual(Priority: TLogPriority): Boolean;
begin
  Result := (Level >= Priority.Level);
end;

{ TLogNDC ---------------------------------------------------------------------}

var
  { The nested diagnostic contexts (NDCs).
    This list has one entry for each thread.
    For each entry, the attached object is another string list
    containing the actual context strings. }
  NDC: TStringList;
  { The controller for synchronisation }
  CriticalNDC: TRTLCriticalSection;

{ Return the current thread id as a string. }
function GetThreadId: string;
begin
  Result := IntToStr(GetCurrentThreadId);
end;

{ Find the index in the NDCs for the current thread. }
function GetNDCIndex: Integer;
begin
  Result := NDC.IndexOf(GetThreadId);
end;

{ Empty out the NDC stack. }
class procedure TLogNDC.Clear;
var
  Index: Integer;
begin
  EnterCriticalSection(CriticalNDC);
  try
    Index := GetNDCIndex;
    if Index > -1 then
    begin
      NDC.Objects[Index].Free;
      NDC.Delete(Index);
    end;
  finally
    LeaveCriticalSection(CriticalNDC);
  end;
end;

{ Retrieve the current NDC for display. }
class function TLogNDC.Context: string;
var
  Index, Index2: Integer;
begin
  EnterCriticalSection(CriticalNDC);
  try
    Result := '';
    Index  := GetNDCIndex;
    if Index = -1 then
      Exit;
    with TStringList(NDC.Objects[Index]) do
      for Index2 := 0 to Count - 1 do
        Result := Result + '|' + Strings[Index2];
    Delete(Result, 1, 1);
  finally
    LeaveCriticalSection(CriticalNDC);
  end;
end;

{ Remove the last context string added to the stack. }
class procedure TLogNDC.Pop;
var
  Index: Integer;
begin
  EnterCriticalSection(CriticalNDC);
  try
    Index := GetNDCIndex;
    if Index = -1 then
      Exit;
    with TStringList(NDC.Objects[Index]) do
      if Count <= 1 then
        TLogNDC.Clear
      else if Count > 0 then
        Delete(Count - 1);
  finally
    LeaveCriticalSection(CriticalNDC);
  end;
end;

{ Add a new context string to the stack. }
class procedure TLogNDC.Push(Context: string);
var
  Index: Integer;
begin
  EnterCriticalSection(CriticalNDC);
  try
    Index := GetNDCIndex;
    if Index = -1 then
      Index := NDC.AddObject(GetThreadId, TStringList.Create);
    with TStringList(NDC.Objects[Index]) do
      Add(Context);
  finally
    LeaveCriticalSection(CriticalNDC)
  end;
end;

{ TLogEvent -------------------------------------------------------------------}

constructor TLogEvent.Create(Category: TLogCategory; Priority: TLogPriority;
  Message: string; Err: Exception);
begin
  inherited Create;
  FCategory  := Category;
  FPriority  := Priority;
  FMessage   := Message;
  FError     := Err;
  FTimeStamp := Now;
end;

{ Immediately render an object into a text message. }
constructor TLogEvent.Create(Category: TLogCategory; Priority: TLogPriority;
  Message: TObject; Err: Exception);
var
  Renderer: ILogRenderer;
begin
  Renderer := Category.Hierarchy.GetRenderer(Message.ClassType);
  if not Assigned(Renderer) then
  begin
    LogLog.Error(Format(NoRendererMsg, [Message.ClassName]));
    Abort;
  end
  else
    Create(Category, Priority, Renderer.Render(Message), Err);
end;

{ The elapsed time since package start up (in milliseconds). }
function TLogEvent.GetElapsedTime: LongInt;
begin
  Result := Round((TimeStamp - StartTime) * MilliSecsPerDay);
end;

{ Return the embedded exceptions message (if there is one). }
function TLogEvent.GetErrorMessage: string;
begin
  if Assigned(Error) then
    Result := Error.Message
  else
    Result := '';
end;

{ Return the nested diagnostic context. }
function TLogEvent.GetNDC: string;
begin
  Result := TLogNDC.Context;
end;

{ Return the current thread ID. }
function TLogEvent.GetThreadId: LongInt;
begin
  Result := GetCurrentThreadId;
end;

{ TLogDefaultCategoryFactory --------------------------------------------------}

function TLogDefaultCategoryFactory.MakeNewCategoryInstance(Name: string):
  TLogCategory;
begin
  Result := TLogCategory.Create(Name);
end;

{ TLogCategory ----------------------------------------------------------------}

constructor TLogCategory.Create(Name: string);
begin
  inherited Create;
  InitializeCriticalSection(FCriticalCategory);
  FAdditive  := True;
  FAppenders := TInterfaceList.Create;
  FName      := Name;
end;

destructor TLogCategory.Destroy;
begin
  FAppenders.Free;
  DeleteCriticalSection(FCriticalCategory);
  inherited Destroy;
end;

procedure TLogCategory.AddAppender(Appender: ILogAppender);
begin
  EnterCriticalSection(FCriticalCategory);
  try
    if FAppenders.IndexOf(Appender) = -1 then
      FAppenders.Add(Appender);
  finally
    LeaveCriticalSection(FCriticalCategory);
  end;
end;

{ Send event to each appender to be logged.
  If additive, also send to parent's appenders. }
procedure TLogCategory.CallAppenders(Event: TLogEvent);
var
  Index: Integer;
begin
  EnterCriticalSection(FCriticalCategory);
  try
    if CountAppenders = 0 then
    begin
      LogLog.Error(Format(NoAppendersMsg, [Name]));
      LogLog.Error(PleaseInitMsg);
      Exit;
    end;
    for Index := 0 to FAppenders.Count - 1 do
      ILogAppender(FAppenders[Index]).Append(Event);
    if Additive and Assigned(Parent) then
      Parent.CallAppenders(Event);
  finally
    LeaveCriticalSection(FCriticalCategory);
  end;
end;

procedure TLogCategory.CloseAllAppenders;
var
  Index: Integer;
begin
  EnterCriticalSection(FCriticalCategory);
  try
    for Index := 0 to FAppenders.Count - 1 do
      ILogAppender(FAppenders[Index]).Close;
  finally
    LeaveCriticalSection(FCriticalCategory);
  end;
end;

{ Include parent's appenders in the count (if additive). }
function TLogCategory.CountAppenders: Integer;
begin
  Result := FAppenders.Count;
  if Additive and Assigned(Parent) then
    Result := Result + Parent.CountAppenders;
end;

procedure TLogCategory.Debug(Message: string; Err: Exception);
begin
  Log(Log4D.Debug, Message, Err);
end;

procedure TLogCategory.Debug(Message: TObject; Err: Exception);
begin
  Log(Log4D.Debug, Message, Err);
end;

{ Create the logging event object and send it to the appenders. }
procedure TLogCategory.DoLog(Priority: TLogPriority; Message: string;
  Err: Exception);
var
  Event: TLogEvent;
begin
  Event := TLogEvent.Create(Self, Priority, Message, Err);
  try
    CallAppenders(Event);
  finally
    Event.Free;
  end;
end;

procedure TLogCategory.DoLog(Priority: TLogPriority; Message: TObject;
  Err: Exception);
var
  Event: TLogEvent;
begin
  Event := TLogEvent.Create(Self, Priority, Message, Err);
  try
    CallAppenders(Event);
  finally
    Event.Free;
  end;
end;

procedure TLogCategory.Error(Message: string; Err: Exception);
begin
  Log(Log4D.Error, Message, Err);
end;

procedure TLogCategory.Error(Message: TObject; Err: Exception);
begin
  Log(Log4D.Error, Message, Err);
end;

procedure TLogCategory.Fatal(Message: string; Err: Exception);
begin
  Log(Log4D.Fatal, Message, Err);
end;

procedure TLogCategory.Fatal(Message: TObject; Err: Exception);
begin
  Log(Log4D.Fatal, Message, Err);
end;

{ Create new categories via the category class. }
class function TLogCategory.GetInstance(Name: string;
  Factory: ILogCategoryFactory): TLogCategory;
begin
  Result := DefaultHierarchy.GetInstance(Name, Factory);
end;

{ Return parent's priority if not set in this category. }
function TLogCategory.GetPriority: TLogPriority;
begin
  if Assigned(FPriority) then
    Result := FPriority
  else
    Result := Parent.Priority;
end;

procedure TLogCategory.Info(Message: string; Err: Exception);
begin
  Log(Log4D.Info, Message, Err);
end;

procedure TLogCategory.Info(Message: TObject; Err: Exception);
begin
  Log(Log4D.Info, Message, Err);
end;

function TLogCategory.IsDebugEnabled: Boolean;
begin
  Result := IsPriorityEnabled(Log4D.Debug);
end;

function TLogCategory.IsErrorEnabled: Boolean;
begin
  Result := IsPriorityEnabled(Log4D.Error);
end;

function TLogCategory.IsFatalEnabled: Boolean;
begin
  Result := IsPriorityEnabled(Log4D.Fatal);
end;

function TLogCategory.IsInfoEnabled: Boolean;
begin
  Result := IsPriorityEnabled(Log4D.Info);
end;

function TLogCategory.IsPriorityEnabled(Priority: TLogPriority): Boolean;
begin
  Result := Priority.IsGreaterOrEqual(Self.Priority);
end;

function TLogCategory.IsWarnEnabled: Boolean;
begin
  Result := IsPriorityEnabled(Log4D.Warn);
end;

{ Synchronise access to the category. }
procedure TLogCategory.LockCategory;
begin
  EnterCriticalSection(FCriticalCategory);
end;

{ Hierarchy can disable logging at a global level. }
procedure TLogCategory.Log(Priority: TLogPriority; Message: string;
  Err: Exception);
begin
  if Hierarchy.IsDisabled(Priority.Level) then
    Exit;
  if IsPriorityEnabled(Priority) then
    DoLog(Priority, Message, Err);
end;

procedure TLogCategory.Log(Priority: TLogPriority; Message: TObject;
  Err: Exception);
begin
  if Hierarchy.IsDisabled(Priority.Level) then
    Exit;
  if IsPriorityEnabled(Priority) then
    DoLog(Priority, Message, Err);
end;

procedure TLogCategory.RemoveAllAppenders;
begin
  EnterCriticalSection(FCriticalCategory);
  try
    FAppenders.Clear;
  finally
    LeaveCriticalSection(FCriticalCategory);
  end;
end;

procedure TLogCategory.RemoveAppender(Appender: ILogAppender);
begin
  EnterCriticalSection(FCriticalCategory);
  try
    FAppenders.Remove(Appender);
  finally
    LeaveCriticalSection(FCriticalCategory);
  end;
end;

{ Release synchronised access to the category. }
procedure TLogCategory.UnlockCategory;
begin
  LeaveCriticalSection(FCriticalCategory);
end;

procedure TLogCategory.Warn(Message: string; Err: Exception);
begin
  Log(Log4D.Warn, Message, Err);
end;

procedure TLogCategory.Warn(Message: TObject; Err: Exception);
begin
  Log(Log4D.Warn, Message, Err);
end;

{ TLogRoot --------------------------------------------------------------------}

const
  InternalRootName = 'root';

constructor TLogRoot.Create(Priority: TLogPriority);
begin
  inherited Create(InternalRootName);
  Self.Priority := Priority;
end;

{ Root category cannot have a nil priority. }
procedure TLogRoot.SetPriority(Priority: TLogPriority);
begin
  if not Assigned(Priority) then
  begin
    LogLog.Error(NilPriorityMsg);
    inherited Priority := Log4D.Debug;
  end
  else
    inherited Priority := Priority;
end;

{ TLogLog ---------------------------------------------------------------------}

{ Initialise internal logging - send it to debugging output. }
constructor TLogLog.Create;
begin
  inherited Create('');
  AddAppender(TLogODSAppender.Create(''));
  InternalDebugging := False;
  Priority          := Log4D.Debug;
end;

{ Only log internal debugging messages when requested. }
procedure TLogLog.DoLog(Priority: TLogPriority; Message: string;
  Err: Exception);
begin
  if (Priority <> Log4D.Debug) or InternalDebugging then
    inherited DoLog(Priority, Message, Err);
end;

procedure TLogLog.DoLog(Priority: TLogPriority; Message: TObject;
  Err: Exception);
begin
  if (Priority <> Log4D.Debug) or InternalDebugging then
    inherited DoLog(Priority, Message, Err);
end;

{ TLogHierarchy ---------------------------------------------------------------}

const
  { DisableOff should be set to a value lower than all possible priorities. }
  DisableOff      = -1;
  DisableOverride = -2;

constructor TLogHierarchy.Create(Root: TLogCategory);
begin
  inherited Create;
  InitializeCriticalSection(FCriticalHierarchy);
  FCategories      := TStringList.Create;
  FRoot            := Root;
  FRoot.Hierarchy  := Self;
  { Don't disable any priority level by default. }
  FDisable         := DisableOff;
  FRenderedClasses := TClassList.Create;
  FRenderers       := TInterfaceList.Create;
end;

destructor TLogHierarchy.Destroy;
begin
  Shutdown;
  Clear;
  FCategories.Free;
  if TLogCategory(FRoot).RefCount > 0 then
    TLogCategory(FRoot)._Release
  else
    FRoot.Free;
  FRenderedClasses.Free;
  FRenderers.Free;
  DeleteCriticalSection(FCriticalHierarchy);
  inherited Destroy;
end;

{ Add an object renderer for a specific class. }
procedure TLogHierarchy.AddRenderer(RenderedClass: TClass;
  Renderer: ILogRenderer);
var
  Index: Integer;
begin
  Index := FRenderedClasses.IndexOf(RenderedClass);
  if Index = -1 then
  begin
    FRenderedClasses.Add(RenderedClass);
    FRenderers.Add(Renderer);
  end
  else
    FRenderers[Index] := Renderer;
end;

{ This call will clear all category definitions from the internal hashtable.
  Invoking this method will irrevocably mess up the category hierarchy.
  You should really know what you are doing before invoking this method. }
procedure TLogHierarchy.Clear;
var
  Index: Integer;
begin
  for Index := 0 to FCategories.Count - 1 do
    if TLogCategory(FCategories.Objects[Index]).RefCount > 0 then
      TLogCategory(FCategories.Objects[Index])._Release
    else
      FCategories.Objects[Index].Free;
  FCategories.Clear;
end;

{ Disable all logging requests of priority equal to or below the
  priority parameter, for all categories in this hierarchy.
  Logging requests of higher priority then specified remain unaffected.

  Nevertheless, if the DisableOverrideKey system property is set to 'true' or
  any value other than 'false', then logging requests are evaluated as usual,
  i.e. according to the Basic Selection Rule.

  The 'disable' family of methods are there for speed. They allow printing
  methods such as debug, info, etc. to return immediately after an integer
  comparison without walking the category hierarchy. In most modern computers
  an integer comparison is measured in nanoseconds where as a category walk
  is measured in units of microseconds. }
procedure TLogHierarchy.Disable(Priority: TLogPriority);
begin
  if (FDisable <> DisableOverride) and Assigned(Priority) then
    FDisable := Priority.Level;
end;

{ Disable all logging requests regardless of category and priority.
  This method is equivalent to calling Disable with the
  argument Fatal, the highest possible priority. }
procedure TLogHierarchy.DisableAll;
begin
  Disable(Fatal);
end;

{ Disable all logging requests of priority Debug regardless of category.
  Invoking this method is equivalent to calling Disable with the
  argument Debug. }
procedure TLogHierarchy.DisableDebug;
begin
  Disable(Debug);
end;

{ Disable all logging requests of priority Info and below
  regardless of category. Note that Debug messages are also disabled.
  Invoking this method is equivalent to calling Disable with the
  argument Info. }
procedure TLogHierarchy.DisableInfo;
begin
  Disable(Info);
end;

{ Undoes the effect of calling any of Disable, DisableAll, DisableDebug,
  or DisableInfo methods. More precisely, invoking this method sets the
  internal variable to its default 'off' value. }
procedure TLogHierarchy.EnableAll;
begin
  FDisable := DisableOff;
end;

{ Check if the named category exists in the hirarchy.
  If so return its reference, otherwise return nil. }
function TLogHierarchy.Exists(Name: string): TLogCategory;
var
  Index: Integer;
begin
  Index := FCategories.IndexOf(Name);
  if Index > -1 then
    Result := TLogCategory(FCategories.Objects[Index])
  else
    Result := nil;
end;

{ Returns all the currently defined categories in this hierarchy as
  a string list (excluding the root category). }
procedure TLogHierarchy.GetCurrentCategories(List: TStringList);
var
  Index: Integer;
begin
  for Index := 0 to FCategories.Count - 1 do
    List.Add(FCategories[Index]);
end;

{ Return a new category instance named as the first parameter using the
  specified factory. If no factory is provided, use the DefaultCategoryFactory.
  If a category of that name already exists, then it will be returned.
  Otherwise, a new category will be instantiated by the factory parameter
  and linked with its existing ancestors as well as children. }
function TLogHierarchy.GetInstance(Name: string; Factory: ILogCategoryFactory):
  TLogCategory;
begin
  EnterCriticalSection(FCriticalHierarchy);
  try
    Result := Exists(Name);
    if not Assigned(Result) then
    begin
      if not Assigned(Factory) then
        Factory := DefaultCategoryFactory;
      Result           := Factory.MakeNewCategoryInstance(Name);
      Result.Hierarchy := Self;
      FCategories.AddObject(Name, Result);
      UpdateParent(Result);
    end;
  finally
    LeaveCriticalSection(FCriticalHierarchy);
  end;
end;

{ Return a renderer for the named class. }
function TLogHierarchy.GetRenderer(RenderedClass: TClass): ILogRenderer;
var
  Index: Integer;
begin
  Result := nil;
  repeat
    Index := FRenderedClasses.IndexOf(RenderedClass);
    if Index > -1 then
      Result := ILogRenderer(FRenderers[Index])
    else
      RenderedClass := RenderedClass.ClassParent;
  until Assigned(Result) or (RenderedClass.ClassName = 'TObject');
end;

{ Check for global disabling of priorities. }
function TLogHierarchy.IsDisabled(Level: Integer): Boolean;
begin
  Result := (FDisable >= Level);
end;

{ Set the disable override value - no priorities can then be disabled. }
procedure TLogHierarchy.OverrideDisable;
begin
  LogLog.Debug(OverrideDisableMsg);
  FDisable := DisableOverride;
end;

{ Reset all values contained in this hierarchy instance to their default.
  This removes all appenders from all categories, sets the priority of
  all non-root categories to nil, sets their additivity flag to true and
  sets the priority of the root category to Debug.
  Moreover, message disabling is set its default 'off' value.
  Existing categories are not removed. They are just reset. }
procedure TLogHierarchy.ResetConfiguration;
var
  Index: Integer;
begin
  EnterCriticalSection(FCriticalHierarchy);
  try
    Root.Priority := Debug;
    FDisable      := DisableOff;

    Shutdown;  { Nested locks are OK }

    for Index := 0 to FCategories.Count - 1 do
      with TLogCategory(FCategories.Objects[Index]) do
      begin
        Priority := nil;
        Additive := True;
      end;
    FRenderedClasses.Clear;
    FRenderers.Clear;
  finally
    LeaveCriticalSection(FCriticalHierarchy);
  end;
end;

{ Shutting down a hierarchy will safely close and remove
  all appenders in all categories including the root category.
  Some appenders need to be closed before the application exists,
  otherwise, pending logging events might be lost. }
procedure TLogHierarchy.Shutdown;
var
  Index: Integer;
begin
  EnterCriticalSection(FCriticalHierarchy);
  try
    Root.CloseAllAppenders;
    Root.RemoveAllAppenders;
    for Index := 0 to FCategories.Count - 1 do
      with TLogCategory(FCategories.Objects[Index]) do
      begin
        CloseAllAppenders;
        RemoveAllAppenders;
      end;
  finally
    LeaveCriticalSection(FCriticalHierarchy);
  end;
end;

{ Set the parent for the specified category.
  The category hierarchy is based on names separated by a dot (.).
  The root is the ultimate parent. Otherwise, we use GetInstance to
  return a reference to the immediate parent (and create it if necessary). }
procedure TLogHierarchy.UpdateParent(Cat: TLogCategory);
var
  Index: Integer;

  { Return the index of the last dot (.) in the text, or zero if none. }
  function LastDot(Text: string): Integer;
  begin
    for Result := Length(Text) downto 1 do
      if Text[Result] = '.' then
        Exit;
    Result := 0;
  end;

begin
  Index := LastDot(Cat.Name);
  if Index = 0 then
    Cat.FParent := Root
  else
    Cat.FParent := GetInstance(Copy(Cat.Name, 1, Index - 1));
end;

{ TLogCustomLayout ------------------------------------------------------------}

{ Returns the content type output by this layout.
  The base class returns 'text/plain'. }
function TLogCustomLayout.GetContentType: string;
begin
  Result := 'text/plain';
end;

{ Returns the footer for the layout format. The base class returns ''. }
function TLogCustomLayout.GetFooter: string;
begin
  Result := '';
end;

{ Returns the header for the layout format. The base class returns ''. }
function TLogCustomLayout.GetHeader: string;
begin
  Result := '';
end;

{ If the layout handles the Exception object contained within, then the
  layout should return False. Otherwise, if the layout ignores Exception
  object, then the layout should return True. The base class returns True. }
function TLogCustomLayout.IgnoresException: Boolean;
begin
  Result := True;
end;

{ Initialisation - date format is a standard option. }
procedure TLogCustomLayout.Init;
begin
  inherited Init;
  SetOption(DateFormatOpt, ShortDateFormat);
end;

{ Set a list of options for this layout. }
procedure TLogCustomLayout.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if (Name = DateFormatOpt) and (Value <> '') then
    DateFormat := Value;
end;

{ TLogSimpleLayout ------------------------------------------------------------}

{ Show event priority and message. }
function TLogSimpleLayout.Format(Event: TLogEvent): string;
begin
  Result := Event.Priority.Name + ' - ' + Event.Message + CRLF;
end;

{ TLogHTMLLayout --------------------------------------------------------------}

{ Write a HTML table row for each event. }
function TLogHTMLLayout.Format(Event: TLogEvent): string;
var
  ErrorMessage: string;
begin
  Result := '<tr><td>' + IntToStr(Event.ElapsedTime) +
    '</td><td>' + IntToStr(Event.ThreadId) + '</td><td>';
  if Event.Priority.IsGreaterOrEqual(Warn) then
    Result := Result + '<font color="#FF0000">' + Event.Priority.Name +
      '</font>'
  else
    Result := Result + Event.Priority.Name;
  Result := Result + '</td><td>' + Event.Category.Name + '</td>' +
    '<td>' + Event.NDC + '</td><td>' + Event.Message + '</td></tr>' + CRLF;
  ErrorMessage := Event.ErrorMessage;
  if ErrorMessage <> '' then
    Result := Result + '<tr><td colspan="6">' + ErrorMessage + '</td></tr>' +
      CRLF;
end;

{ Returns the content type output by this layout, i.e 'text/html'. }
function TLogHTMLLayout.GetContentType: string;
begin
  Result := 'text/html';
end;

{ Returns appropriate HTML footers. }
function TLogHTMLLayout.GetFooter: string;
begin
  Result := '</table></body></html>' + CRLF;
end;

{ Returns appropriate HTML headers. }
function TLogHTMLLayout.GetHeader: string;
begin
  Result := '<html><body>' + CRLF +
    '<table border="1" cellpadding="2">' + CRLF +
    '<tr><th>' + TimeHdr + '</th><th>' + ThreadHdr + '</th>' +
    '<th>' + PriorityHdr + '</th><th>' + CategoryHdr + '</th>' +
    '<th>' + NDCHdr + '</th><th>' + MessageHdr + '</th></tr>' + CRLF;
end;

{ The HTML layout handles the exception contained in logging events.
  Hence, this method return False. }
function TLogHTMLLayout.IgnoresException: Boolean;
begin
  Result := False;
end;

{ TLogPatternLayout -----------------------------------------------------------}

type
  TPatternPart = (ppText, ppCategory, ppClassName, ppDate, ppException,
    ppFileName, ppLocation, ppLine, ppMessage, ppMethod, ppNewLine,
    ppPriority, ppRuntime, ppThread, ppNDC, ppPercent);

const
  { These characters identify the types above. }
  PatternChars        = ' cCdeFlLmMnprtx%';
  { These characters substitute for those above in the processed format. }
  PatternReplacements = ' ssssssdssssddss';

constructor TLogPatternLayout.Create(Pattern: string);
begin
  inherited Create;
  Self.Pattern := Pattern;
end;

destructor TLogPatternLayout.Destroy;
begin
  FPatternParts.Free;
  inherited Destroy;
end;

{ Compile the formatted string from the specified pattern and its parts.
  Pattern characters are as follows:
  c - Category name, e.g. myapp.more
  C - Class name of caller - not implemented
  e - Message from the exception associated with the event
  d - Current date and time, using date format set as option
  F - File name of calling class - not implemented
  l - Name and location within calling method - not implemented
  L - Line number within calling method - not implemented
  m - Message associated with event
  M - Method name within calling class - not implemented
  n - New line
  p - Priority name
  r - Runtime in milliseconds since start
  t - Thread id
  x - Nested diagnostic context (NDC)
  % - The percent character
  Pattern characters are preceded by a percent sign (%) and may contain
  field formatting characters per Delphi's Format function, e.g. %-7p
  displays the event's priority, left justified in a 7 character field.
  Other text is displayed as is. }
function TLogPatternLayout.Format(Event: TLogEvent): string;
var
  Index: Integer;
begin
  Result := '';
  for Index := 0 to FPatternParts.Count - 1 do
    case TPatternPart(FPatternParts.Objects[Index]) of
      ppText:      Result := Result + FPatternParts[Index];
      ppCategory:  Result := Result +
        SysUtils.Format(FPatternParts[Index], [Event.Category.Name]);
      ppClassName: Result := Result +
        SysUtils.Format(FPatternParts[Index], [ValueUnknownMsg]);
      ppDate:      Result := Result + FormatDateTime(DateFormat, Now);
      ppException: Result := Result +
        SysUtils.Format(FPatternParts[Index], [Event.ErrorMessage]);
      ppFileName:  Result := Result +
        SysUtils.Format(FPatternParts[Index], [ValueUnknownMsg]);
      ppLocation:  Result := Result +
        SysUtils.Format(FPatternParts[Index], [ValueUnknownMsg]);
      ppLine:      Result := Result +
        SysUtils.Format(FPatternParts[Index], [ValueUnknownMsg]);
      ppMessage:   Result := Result +
        SysUtils.Format(FPatternParts[Index], [Event.Message]);
      ppMethod:    Result := Result +
        SysUtils.Format(FPatternParts[Index], [ValueUnknownMsg]);
      ppNewLine:   Result := Result + CRLF;
      ppPriority:  Result := Result +
        SysUtils.Format(FPatternParts[Index], [Event.Priority.Name]);
      ppRuntime:   Result := Result + SysUtils.Format(FPatternParts[Index],
        [Event.ElapsedTime]);
      ppThread:    Result := Result +
        SysUtils.Format(FPatternParts[Index], [Event.ThreadId]);
      ppNDC:       Result := Result +
        SysUtils.Format(FPatternParts[Index], [Event.NDC]);
      ppPercent:   Result := Result + '%';
    end;
end;

procedure TLogPatternLayout.Init;
begin
  inherited Init;
  FPatternParts := TStringList.Create;
end;

procedure TLogPatternLayout.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if (Name = PatternOpt) and (Value <> '') then
    Pattern := Value;
end;

{ Extract the portions of the pattern for easier processing later. }
procedure TLogPatternLayout.SetPattern(Pattern: string);
var
  Index: Integer;
  Part: string;
  PartType: TPatternPart;
begin
  FPattern := Pattern;
  FPatternParts.Clear;
  Part     := '';
  Index    := 1;
  while Index <= Length(FPattern) do
  begin
    if FPattern[Index] = '%' then
    begin
      { Patterns are delimited by percents (%) and continue up to
        one of the special characters noted earlier. }
      repeat
        Part := Part + FPattern[Index];
        Inc(Index);
      until (Index > Length(FPattern)) or
        (Pos(FPattern[Index], PatternChars) > 1);
      if Index > Length(FPattern) then
        Part := Part + 'm'
      else
        Part := Part + FPattern[Index];
      PartType := TPatternPart(Pos(Part[Length(Part)], PatternChars) - 1);
      Part[Length(Part)] :=
        PatternReplacements[Pos(FPattern[Index], PatternChars)];
      FPatternParts.AddObject(Part, Pointer(Integer(PartType)));
      Part := '';
      Inc(Index);
    end
    else
    begin
      { The rest is straight text - up to the next percent (%). }
      repeat
        Part := Part + FPattern[Index];
        Inc(Index);
      until (Index > Length(FPattern)) or (FPattern[Index] = '%');
      FPatternParts.AddObject(Part, Pointer(Integer(ppText)));
      Part := '';
    end;
  end;
end;

{ TLogOnlyOnceErrorHandler ----------------------------------------------------}

{ Only first error sent here is reported. }
procedure TLogOnlyOnceErrorHandler.Error(Message: string);
begin
  if not FSeenError then
  begin
    LogLog.Error(Message);
    FSeenError := True;
  end;
end;

procedure TLogOnlyOnceErrorHandler.Error(Message: string; Err: Exception;
  ErrorCode: Integer);
begin
  if not FSeenError then
    Error(Format('%s - (%d) %s', [Message, Err.Message, ErrorCode]));
end;

{ TLogCustomFilter ------------------------------------------------------------}

{ Set common option. }
procedure TLogCustomFilter.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if Name = AcceptMatchOpt then
    FAcceptOnMatch := StrToBool(Value, True);
end;

{ TLogPriorityFilter ----------------------------------------------------------}

constructor TLogPriorityFilter.Create(Match: TLogPriority;
  AcceptOnMatch: Boolean);
begin
  inherited Create;
  Self.AcceptOnMatch := AcceptOnMatch;
  Self.Match         := Match;
end;

{ Check for the matching priority, then accept or deny based on the flag. }
function TLogPriorityFilter.Decide(Event: TLogEvent): TLogFilterDecision;
begin
  if Assigned(Match) and (Match = Event.Priority) then
  begin
    if AcceptOnMatch then
      Result := fdAccept
    else
      Result := fdDeny;
  end
  else
    Result := fdNeutral;
end;

procedure TLogPriorityFilter.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if Name = MatchOpt then
    FMatch := GetPriority(Value);
end;

{ TLogStringFilter ------------------------------------------------------------}

constructor TLogStringFilter.Create(Match: string; AcceptOnMatch: Boolean);
begin
  inherited Create;
  Self.AcceptOnMatch := AcceptOnMatch;
  Self.Match         := Match;
end;

{ Check for the matching string, then accept or deny based on the flag. }
function TLogStringFilter.Decide(Event: TLogEvent): TLogFilterDecision;
begin
  if Pos(Match, Event.Message) > 0 then
  begin
    if AcceptOnMatch then
      Result := fdAccept
    else
      Result := fdDeny;
  end
  else
    Result := fdNeutral;
end;

procedure TLogStringFilter.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if Name = MatchOpt then
    FMatch := Value;
end;

{ TLogCustomAppender ----------------------------------------------------------}

constructor TLogCustomAppender.Create(Name: string; Layout: ILogLayout);
begin
  inherited Create;
  FName := Name;
  if Assigned(Layout) then
    FLayout := Layout
  else
    FLayout := TLogSimpleLayout.Create;
end;

destructor TLogCustomAppender.Destroy;
begin
  Close;
  FFilters.Free;
  DeleteCriticalSection(FCriticalAppender);
  inherited Destroy;
end;

{ Add a filter to the end of the filter list. }
procedure TLogCustomAppender.AddFilter(Filter: ILogFilter);
begin
  if FFilters.IndexOf(Filter) = -1 then
    FFilters.Add(Filter);
end;

{ Log in appender-specific way. }
procedure TLogCustomAppender.Append(Event: TLogEvent);
begin
  EnterCriticalSection(FCriticalAppender);
  try
    if CheckEntryConditions then
      if CheckFilters(Event) then
        DoAppend(Event);
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

{ Only log if not closed and a layout is available. }
function TLogCustomAppender.CheckEntryConditions: Boolean;
begin
  Result := False;
  if FClosed then
  begin
    LogLog.Warn(ClosedAppenderMsg);
    Exit;
  end;
  if not Assigned(Layout) then
  begin
    ErrorHandler.Error(Format(NoLayoutMsg, [Name]));
    Exit;
  end;
  Result := True;
end;

{ Only log if any/all filters allow it. }
function TLogCustomAppender.CheckFilters(Event: TLogEvent): Boolean;
var
  Index: Integer;
begin
  for Index := 0 to FFilters.Count - 1 do
    case ILogFilter(FFilters[Index]).Decide(Event) of
      fdAccept:  begin
                   Result := True;
                   Exit;
                 end;
      fdDeny:    begin
                   Result := False;
                   Exit;
                 end;
      fdNeutral: { Try next one }
    end;
  Result := True;
end;

{ Release any resources allocated within the appender such as file
  handles, network connections, etc.
  It is a programming error to append to a closed appender. }
procedure TLogCustomAppender.Close;
begin
  EnterCriticalSection(FCriticalAppender);
  try
    if FClosed then
      Exit;
    WriteFooter;
    FClosed := True;
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

procedure TLogCustomAppender.DoAppend(Event: TLogEvent);
begin
  DoAppend(Layout.Format(Event));
end;

{ Returns the error handler for this appender. }
function TLogCustomAppender.GetErrorHandler: ILogErrorHandler;
begin
  Result := FErrorHandler;
end;

{ Returns the filters for this appender. }
function TLogCustomAppender.GetFilters: TInterfaceList;
begin
  Result := FFilters;
end;

{ Returns this appender's layout. }
function TLogCustomAppender.GetLayout: ILogLayout;
begin
  Result := FLayout;
end;

{ Get the name of this appender. The name uniquely identifies the appender. }
function TLogCustomAppender.GetName: string;
begin
  Result := FName;
end;

{ Initialisation. }
procedure TLogCustomAppender.Init;
begin
  inherited Init;
  InitializeCriticalSection(FCriticalAppender);
  FClosed       := False;
  FErrorHandler := TLogOnlyOnceErrorHandler.Create;
  FFilters      := TInterfaceList.Create;
end;

{ Clear the list of filters by removing all the filters in it. }
procedure TLogCustomAppender.RemoveAllFilters;
begin
  FFilters.Clear;
end;

{ Delete a filter from the appender's list. }
procedure TLogCustomAppender.RemoveFilter(Filter: ILogFilter);
begin
  FFilters.Remove(Filter);
end;

{ Configurators call this method to determine if the appender requires
  a layout. If this method returns True, meaning that a layout is required,
  then the configurator will configure a layout using the configuration
  information at its disposal.  If this method returns False, meaning that
  a layout is not required, then layout configuration will be skipped even
  if there is available layout configuration information at the disposal
  of the configurator.
  In the rather exceptional case, where the appender implementation admits a
  layout but can also work without it, then the appender should return True. }
function TLogCustomAppender.RequiresLayout: Boolean;
begin
  Result := True;
end;

{ Set the error handler for this appender - it cannot be nil. }
procedure TLogCustomAppender.SetErrorHandler(ErrorHandler: ILogErrorHandler);
begin
  EnterCriticalSection(FCriticalAppender);
  try
    if not Assigned(ErrorHandler) then
      LogLog.Warn(NilErrorHandlerMsg)
    else
      FErrorHandler := ErrorHandler;
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

{ Set the layout for this appender. }
procedure TLogCustomAppender.SetLayout(Layout: ILogLayout);
begin
  FLayout := Layout;
end;

{ Set the name of this appender. The name is used by other
  components to identify this appender. }
procedure TLogCustomAppender.SetName(Name: string);
begin
  FName := Name;
end;

procedure TLogCustomAppender.WriteFooter;
begin
  if Assigned(Layout) then
    DoAppend(Layout.Footer);
end;

procedure TLogCustomAppender.WriteHeader;
begin
  if Assigned(Layout) then
    DoAppend(Layout.Header);
end;

{ TLogNullAppender ------------------------------------------------------------}

{ Do nothing. }
procedure TLogNullAppender.DoAppend(Message: string);
begin
end;

{ TLogODSAppender -------------------------------------------------------------}

{ Log to debugging output. }
procedure TLogODSAppender.DoAppend(Message: string);
begin
  OutputDebugString(PChar(Message));
end;

{ TLogStreamAppender ----------------------------------------------------------}

constructor TLogStreamAppender.Create(Name: string; Stream: TStream;
  Layout: ILogLayout);
begin
  inherited Create(Name, Layout);
  FStream := Stream;
end;

destructor TLogStreamAppender.Destroy;
begin
  Close;
  FStream.Free;
  inherited Destroy;
end;

{ Log to the attached stream. }
procedure TLogStreamAppender.DoAppend(Message: string);
var
  StrStream: TStringStream;
begin
  if Assigned(FStream) then
  begin
    StrStream := TStringStream.Create(Message);
    try
      FStream.CopyFrom(StrStream, 0);
    finally
      StrStream.Free;
    end;
  end;
end;

{ TLogFileAppender ------------------------------------------------------------}

{ Create a file stream and delegate to the parent class. }
constructor TLogFileAppender.Create(Name, FileName: string; Layout: ILogLayout;
  Append: Boolean);
begin
  inherited Create(Name, nil, Layout);
  FAppend := Append;
  SetOption(FileNameOpt, FileName);
end;

procedure TLogFileAppender.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  EnterCriticalSection(FCriticalAppender);
  try
    if (Name = AppendOpt) and (Value <> '') then
    begin
      FAppend := StrToBool(Value, FAppend);
    end;
    if (Name = FileNameOpt) and (Value <> '') then
    begin
      if Assigned(FStream) then
        FStream.Free;
      FFileName := Value;
      if FAppend and FileExists(FFileName) then
      begin
        FStream := TFileStream.Create(FFileName,
          fmOpenReadWrite or fmShareExclusive);
        FStream.Seek(0, soFromEnd);
      end
      else
        FStream := TFileStream.Create(FFileName, fmCreate or fmShareExclusive);
      WriteHeader;
    end;
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

{ OptionConvertors ------------------------------------------------------------}

{ Convert string value to Boolean, with default. }
function StrToBool(Value: string; Default: Boolean): Boolean;
begin
  Value := UpperCase(Value);
  if (Value = 'TRUE') or (Value = 'YES') then
    Result := True
  else if (Value = 'FALSE') or (Value = 'NO') then
    Result := False
  else
    Result := Default;
end;

{ TAppender -------------------------------------------------------------------}

type
  { Holder for an appender reference. }
  TAppender = class(TObject)
  public
    Appender: ILogAppender;
    constructor Create(Appender: ILogAppender);
  end;

constructor TAppender.Create(Appender: ILogAppender);
begin
  inherited Create;
  Self.Appender := Appender;
end;

{ TLogBasicConfigurator -------------------------------------------------------}

constructor TLogBasicConfigurator.Create;
begin
  inherited Create;
  FCategoryFactory := TLogDefaultCategoryFactory.Create;
  FRegistry        := TStringList.Create;
end;

destructor TLogBasicConfigurator.Destroy;
var
  Index: Integer;
begin
  for Index := 0 to FRegistry.Count - 1 do
    FRegistry.Objects[Index].Free;
  FRegistry.Free;
  inherited Destroy;
end;

{ Used by subclasses to add a renderer to the hierarchy passed as parameter. }
procedure TLogBasicConfigurator.AddRenderer(Hierarchy: TLogHierarchy;
  RenderedName, RendererName: string);
var
  Rendered: TClass;
  Renderer: ILogRenderer;
begin
  LogLog.Debug(Format(RendererMsg, [RendererName, RenderedName]));
  Rendered := FindRendered(RenderedName);
  Renderer := FindRenderer(RendererName);
  if not Assigned(Rendered) then
  begin
    LogLog.Error(Format(NoRenderedCreatedMsg, [RenderedName]));
    Exit;
  end;
  if not Assigned(Renderer) then
  begin
    LogLog.Error(Format(NoRendererCreatedMsg, [RendererName]));
    Exit;
  end;

  Hierarchy.AddRenderer(Rendered, Renderer);
end;

{ Return a reference to an already defined named appender, or nil if none. }
function TLogBasicConfigurator.AppenderGet(Name: string): ILogAppender;
var
  Index: Integer;
begin
  Index := FRegistry.IndexOf(Name);
  if Index = -1 then
    Result := nil
  else
    Result := TAppender(FRegistry.Objects[Index]).Appender;
end;

{ Save reference to named appender. }
procedure TLogBasicConfigurator.AppenderPut(Appender: ILogAppender);
begin
  FRegistry.AddObject(Appender.Name, TAppender.Create(Appender));
end;

{ Add appender to the root category. If no appender is provided,
  add a TLogODSAppender that uses TLogPatternLayout with the
  TTCCPattern and prints to debugging output for the root category. }
class procedure TLogBasicConfigurator.Configure(Appender: ILogAppender);
begin
  if not Assigned(Appender) then
    Appender := TLogODSAppender.Create('ODS',
      TLogPatternLayout.Create(TTCCPattern));
  DefaultHierarchy.Root.AddAppender(Appender);
end;

{ Reset the default hierarchy to its default. }
class procedure TLogBasicConfigurator.ResetConfiguration;
begin
  DefaultHierarchy.ResetConfiguration;
end;

{ Initialise standard global settings. }
procedure TLogBasicConfigurator.SetGlobalProps(Hierarchy: TLogHierarchy;
  FactoryClassName, Debug, Disable, DisableOverride: string);
begin
  if FactoryClassName <> '' then
  begin
    FCategoryFactory := FindCategoryFactory(FactoryClassName);
    if Assigned(FCategoryFactory) then
      LogLog.Debug(Format(CategoryFactoryMsg, [FactoryClassName]))
    else
      FCategoryFactory := TLogDefaultCategoryFactory.Create;
  end;

  if Debug <> '' then
    LogLog.InternalDebugging := StrToBool(Debug, True);

  { Check if the config file overrides the shipped code flag. }
  if (DisableOverride <> '') and StrToBool(DisableOverride, True) then
    Hierarchy.OverrideDisable;

  if (DisableOverride = '') and (Disable <> '') then
    Hierarchy.Disable(GetPriority(Disable));
end;

{ TLogPropertyConfigurator ----------------------------------------------------}

{ Split the supplied value into tokens with specified delimiters. }
procedure Tokenise(Value: string; var Items: TStringList; Delimiters: string);
var
  Index: Integer;
  Item: string;
begin
  Item := '';
  for Index := 1 to Length(Value) do
    if Pos(Value[Index], Delimiters) > 0 then
    begin
      Items.Add(Item);
      Item := '';
    end
    else
      Item := Item + Value[Index];
  if Item <> '' then
    Items.Add(Item);
end;

{ Extract properties with the given prefix from the supplied list
  and send them to the option handler. }
procedure SetSubProps(Prefix: string; Props: TStringList;
  Handler: ILogOptionHandler);
var
  Index: Integer;
begin
  for Index := 0 to Props.Count - 1 do
    if Pos(Prefix, Props.Names[Index]) = 1 then
      Handler.Options[Copy(Props.Names[Index], Length(Prefix) + 2, 255)] :=
        Props.Values[Props.Names[Index]];
end;

{ Read configuration options from a file.
  See DoConfigure for the expected format. }
class procedure TLogPropertyConfigurator.Configure(Filename: string);
var
  Config: TLogPropertyConfigurator;
begin
  Config := TLogPropertyConfigurator.Create;
  try
    Config.DoConfigure(Filename, DefaultHierarchy);
  finally
    Config.Free;
  end;
end;

{ Read configuration options from properties.
  See DoConfigure for the expected format. }
class procedure TLogPropertyConfigurator.Configure(Props: TStringList);
var
  Config: TLogPropertyConfigurator;
begin
  Config := TLogPropertyConfigurator.Create;
  try
    Config.DoConfigure(Props, DefaultHierarchy);
  finally
    Config.Free;
  end;
end;

procedure TLogPropertyConfigurator.ConfigureRootCategory(Props: TStringList;
  Hierarchy: TLogHierarchy);
var
  Value: string;
begin
  Value := Props.Values[RootCategoryKey];
  if Value = '' then
    LogLog.Debug(NoRootCategoryMsg)
  else
    ParseCategory(Props, Hierarchy.Root, Value);
end;

{ Read configuration options from a file.
  See DoConfigure below for the expected format. }
procedure TLogPropertyConfigurator.DoConfigure(FileName: string;
  Hierarchy: TLogHierarchy);
var
  Props: TStringList;
begin
  Props := TStringList.Create;
  try
    try
      Props.LoadFromFile(FileName);
      DoConfigure(Props, Hierarchy);
    except on Ex: Exception do
      begin
        LogLog.Error(Format(BadConfigFileMsg, [FileName, Ex.Message]));
        LogLog.Error(Format(IgnoreConfigMsg, [FileName]));
      end;
    end;
  finally
    Props.Free;
  end;
end;

{ Read configuration from properties. The existing configuration is not
  cleared nor reset. If you require a different behaviour, then call
  ResetConfiguration method before calling Configure.

  The configuration file consists of entries in the format key=value.

  Global Settings

  The user can override any of the Hierarchy.Disable family of methods
  by setting the key 'log4d.disableOverride' to TRUE or any value
  other than FALSE. As in:

  log4d.disableOverride=TRUE

  To set a global disabling of priorities use the following syntax:

  log4d.disable=FATAL|ERROR|WARN|INFO|DEBUG

  The disable override, as its name suggests, overrides any setting made
  using the above entry.

  Logging of internal debugging events can be enabled with the following:

  log4d.debug=TRUE

  Appender configuration

  Appender configuration syntax is:

  # For appender named appenderName, set its class.
  log4d.appender.appenderName=nameOfAppenderClass

  # Set appender specific options.
  log4d.appender.appenderName.option1=value1
    :
  log4d.appender.appenderName.optionN=valueN

  For each named appender you can configure its ErrorHandler.
  The syntax for configuring an appender's error handler is:

  log4d.appender.appenderName.errorHandler=nameOfErrorHandlerClass

  For each named appender you can configure its Layout.
  The syntax for configuring an appender's layout and its options is:

  log4d.appender.appenderName.layout=nameOfLayoutClass
  log4d.appender.appenderName.layout.option1=value1
    :
  log4d.appender.appenderName.layout.optionN=valueN

  For each named appender you can configure its Filters. The syntax for
  configuring an appender's filters is (where x is a sequential number):

  log4d.appender.appenderName.filterx=nameOfFilterClass
  log4d.appender.appenderName.filterx.option1=value1
    :
  log4d.appender.appenderName.filterx.optionN=valueN

  Configuring categories

  The syntax for configuring the root category is:

  log4d.rootCategory=[FATAL|ERROR|WARN|INFO|DEBUG],appenderName,appenderName,...

  This syntax means that one of the strings values ERROR, WARN, INFO, or
  DEBUG can be supplied followed by appender names separated by commas.

  If one of the optional priority values is given, the root priority is set
  to the corresponding priority. If no priority value is specified,
  then the root priority remains untouched.

  The root category can be assigned multiple appenders.

  Each appenderName (separated by commas) will be added to the root category.
  The named appender is defined using the appender syntax defined above.

  For non-root categories the syntax is almost the same:

  log4d.category.categoryName=[INHERITED|FATAL|ERROR|WARN|INFO|DEBUG],appenderName,appenderName,...

  Thus, one of the usual priority values FATAL, ERROR, WARN, INFO, or
  DEBUG can be optionally specified. For any any of these values the
  named category is assigned the corresponding priority. In addition
  however, the value INHERITED can be optionally specified which means
  that named category should inherit its priority from the category hierarchy.

  If no priority value is supplied, then the priority of the
  named category remains untouched.

  By default categories inherit their priority from the hierarchy.
  However, if you set the priority of a category and later decide
  that that category should inherit its priority, then you should
  specify INHERITED as the value for the priority value.

  Similar to the root category syntax, each appenderName
  (separated by commas) will be attached to the named category.

  Category additivity is set in the following fashion:

  log4d.additive.categoryName=TRUE|FALSE

  ObjectRenderers

  You can customize the way message objects of a given type are converted to
  a string before being logged. This is done by specifying an object renderer
  for the object type would like to customize. The syntax is:

  log4d.renderer.nameOfRenderedClass=nameOfRenderingClass

  As in,

  log4d.renderer.TFruit=TFruitRenderer

  Class Factories

  In case you are using your own sub-types of the TLogCategory class and
  wish to use configuration files, then you must set the CategoryFactory
  for the sub-type that you are using. The syntax is:

  log4d.categoryFactory=nameOfCategoryFactoryClass

  Example

  An example configuration is given below.

  # Set internal debugging
  log4d.debug=TRUE

  # Global disable level - don't show debug or info events
  log4d.disable=INFO

  # Override global disable level
  # log4d.disableOverride=TRUE

  # Set category factory - this is the default anyway
  log4d.categoryFactory=TLogDefaultCategoryFactory

  # Set root priority to log warnings and above - sending to appender ODS
  log4d.rootCategory=WARN,ODS

  # Establish category hierarchy
  # 'myapp' inherits its priority from root
  log4d.category.myapp=INHERITED,Mem1
  # 'myapp.more' displays all messages (from debug up)
  log4d.category.myapp.more=DEBUG,Mem2
  # 'myapp.other' doesn't display debug messages
  log4d.category.myapp.other=INFO,Mem3
  # 'alt' only displays error and fatal messages
  log4d.category.alt=ERROR,Mem4,Fil1

  # 'myapp.other' category doesn't log to its parents - others do
  log4d.additive.myapp.other=FALSE

  # Create root appender - logging to debugging output
  log4d.appender.ODS=TLogODSAppender
  # Using the simple layout, i.e. message only
  log4d.appender.ODS.layout=TLogSimpleLayout

  # Create memo appenders, with layouts
  log4d.appender.Mem1=TMemoAppender
  # Specify the name of the memo component to attach to
  log4d.appender.Mem1.memo=memMyapp
  # Use a pattern layout
  log4d.appender.Mem1.layout=TLogPatternLayout
  # With the specified pattern: runtime (in field of 7 characters),
  # thread id (left justified in field of 8 characters), priority,
  # category, NDC, message, and a new line
  log4d.appender.Mem1.layout.pattern=%7r [%-8t] %p %c %x - %m%n
  # Add a string filter
  log4d.appender.Mem1.filter1=TLogStringFilter
  # That matches on 'x'
  log4d.appender.Mem1.filter1.match=x
  # And accepts all messages containing it
  log4d.appender.Mem1.filter1.acceptOnMatch=TRUE
  # Add a second string filter
  log4d.appender.Mem1.filter2=TLogStringFilter
  # That matches on 'y'
  log4d.appender.Mem1.filter2.match=y
  # And discards all messages containing it
  # Note: messages with 'x' and 'y' will be logged as filter 1 is checked first
  log4d.appender.Mem1.filter2.acceptOnMatch=FALSE

  log4d.appender.Mem2=TMemoAppender
  log4d.appender.Mem2.memo=memMyappMore
  log4d.appender.Mem2.layout=TLogSimpleLayout

  log4d.appender.Mem3=TMemoAppender
  log4d.appender.Mem3.memo=memMyappOther
  log4d.appender.Mem3.layout=TLogHTMLLayout

  log4d.appender.Mem4=TMemoAppender
  log4d.appender.Mem4.memo=memAlt
  log4d.appender.Mem4.layout=TLogPatternLayout
  log4d.appender.Mem4.layout.pattern=>%m<%n

  # Create a file appender
  log4d.appender.Fil1=TLogFileAppender
  log4d.appender.Fil1.filename=C:\Temp\Log4D.log
  log4d.appender.Fil1.errorHandler=TLogOnlyOnceErrorHandler
  log4d.appender.Fil1.layout=TLogPatternLayout
  log4d.appender.Fil1.layout.pattern=%r [%t] %p %c %x - %m%n

  # Nominate renderers - when objects of type TEdit are presented,
  # use TComponentRenderer to display them
  log4d.renderer.TEdit=TComponentRenderer

  Use the # character at the beginning of a line for comments. }
procedure TLogPropertyConfigurator.DoConfigure(Props: TStringList;
  Hierarchy: TLogHierarchy);
begin
  SetGlobalProps(Hierarchy,
    Props.Values[CategoryFactoryKey], Props.Values[DebugKey],
    Props.Values[DisableOverrideKey], Props.Values[DisableKey]);

  ConfigureRootCategory(Props, Hierarchy);
  ParseCategoriesAndRenderers(Props, Hierarchy);

  LogLog.Debug(Format(FinishedConfigMsg, [ClassName]));
end;

const
  Bool: array [Boolean] of string = ('False', 'True');

{ Parse the additivity option for a non-root category. }
procedure TLogPropertyConfigurator.ParseAdditivityForCategory(
  Props: TStringList; Cat: TLogCategory);
var
  Value: string;
begin
  Value := Props.Values[AdditiveKey + Cat.Name];
  LogLog.Debug(Format(HandlingAdditivityMsg, [AdditiveKey + Cat.Name, Value]));
  { Touch additivity only if necessary }
  if Value <> '' then
  begin
    Cat.Additive := StrToBool(Value, True);
    LogLog.Debug(Format(SettingAdditivityMsg, [Cat.Name, Bool[Cat.Additive]]));
  end;
end;

{ Parse entries for an appender and its constituents. }
function TLogPropertyConfigurator.ParseAppender(Props: TStringList;
  AppenderName: string): ILogAppender;
var
  Prefix, SubPrefix: string;
  ErrorHandler: ILogErrorHandler;
  Layout: ILogLayout;
  Filter: ILogFilter;
  Index: Integer;
begin
  Result := AppenderGet(AppenderName);
  if Assigned(Result) then
  begin
    LogLog.Debug(Format(AppenderDefinedMsg, [AppenderName]));
    Exit;
  end;

  { Appender was not previously initialised. }
  Prefix := AppenderKey + AppenderName;
  Result := FindAppender(Props.Values[Prefix]);
  if not Assigned(Result) then
  begin
    LogLog.Error(Format(NoAppenderCreatedMsg, [AppenderName]));
    Exit;
  end;

  Result.Name := AppenderName;

  { Process any error handler entry. }
  SubPrefix    := Prefix + ErrorHandlerKey;
  ErrorHandler := FindErrorHandler(Props.Values[SubPrefix]);
  if Assigned(ErrorHandler) then
  begin
    Result.ErrorHandler := ErrorHandler;
    LogLog.Debug(Format(ParsingErrorHandlderMsg, [AppenderName]));
    SetSubProps(SubPrefix, Props, ErrorHandler);
    LogLog.Debug(Format(EndErrorHandlerMsg, [AppenderName]));
  end;

  { Process any layout entry. }
  SubPrefix := Prefix + LayoutKey;
  Layout    := FindLayout(Props.Values[SubPrefix]);
  if Assigned(Layout) then
  begin
    Result.Layout := Layout;
    LogLog.Debug(Format(ParsingLayoutMsg, [AppenderName]));
    SetSubProps(SubPrefix, Props, Layout);
    LogLog.Debug(Format(EndLayoutMsg, [AppenderName]));
  end;
  if Result.RequiresLayout and not Assigned(Result.Layout) then
    LogLog.Error(Format(LayoutRequiredMsg, [AppenderName]));

  { Process any filter entries. }
  SubPrefix := Prefix + FilterKey;
  for Index := 0 to Props.Count - 1 do
    if (Copy(Props.Names[Index], 1, Length(SubPrefix)) = SubPrefix) and
        (Pos('.', Copy(Props.Names[Index], Length(SubPrefix), 255)) = 0) then
    begin
      Filter := FindFilter(Props.Values[Props.Names[Index]]);
      if not Assigned(Filter) then
        Continue;

      Result.AddFilter(Filter);
      LogLog.Debug(Format(ParsingFiltersMsg, [AppenderName]));
      SetSubProps(Props.Names[Index], Props, Filter);
      LogLog.Debug(Format(EndFiltersMsg, [AppenderName]));
    end;

  { Set any options for the appender. }
  SetSubProps(Prefix, Props, Result);

  LogLog.Debug(Format(EndAppenderMsg, [AppenderName]));
  AppenderPut(Result);
end;

{ Parse non-root elements, such as non-root categories and renderers. }
procedure TLogPropertyConfigurator.ParseCategoriesAndRenderers(
  Props: TStringList; Hierarchy: TLogHierarchy);
var
  Index: Integer;
  Key, Name: string;
  Category: TLogCategory;
begin
  for Index := 0 to Props.Count - 1 do
  begin
    Key := Props.Names[Index];
    if Copy(Key, 1, Length(CategoryKey)) = CategoryKey then
    begin
      Name     := Copy(Key, Length(CategoryKey) + 1, 255);
      Category := Hierarchy.GetInstance(Name, FCategoryFactory);
      Category.LockCategory;
      try
        ParseCategory(Props, Category, Props.Values[Key]);
        ParseAdditivityForCategory(Props, Category);
      finally
        Category.UnlockCategory;
      end;
    end
    else if Copy(Key, 1, Length(RendererKey)) = RendererKey then
      AddRenderer(Hierarchy,
        Copy(Key, Length(CategoryKey) + 1, 255), Props.Values[Key]);
  end;
end;

{ This method must work for the root category as well. }
procedure TLogPropertyConfigurator.ParseCategory(Props: TStringList;
  Cat: TLogCategory; Value: string);
var
  Appender: ILogAppender;
  Index: Integer;
  Items: TStringList;
begin
  LogLog.Debug(Format(ParsingCategoryMsg, [Cat.Name, Value]));
  Items := TStringList.Create;
  try
    { We must skip over ',' but not white space }
    Tokenise(Value, Items, ',');
    if Items.Count = 0 then
      Exit;
    { If value is not in the form ", appender.." or "", then we should set
      the priority of the category. }
    if Items[0] <> '' then
    begin
      LogLog.Debug(Format(PriorityTokenMsg, [Items[0]]));

      { If the priority value is inherited, set category priority value to nil.
        We also check that the user has not specified inherited for the
        root category. }
      if (UpperCase(Items[0]) = InheritedPriority) and
          (Cat.Name <> InternalRootName) then
        Cat.Priority := nil
      else
        Cat.Priority := GetPriority(UpperCase(Items[0]));
      LogLog.Debug(Format(SettingPriorityMsg, [Cat.Name, Cat.Priority.Name]));
    end;

    { Remove all existing appenders. They will be reconstructed below. }
    Cat.RemoveAllAppenders;

    for Index := 1 to Items.Count - 1 do
    begin
      if Items[Index] = '' then
        Continue;
      LogLog.Debug(Format(ParsingAppenderMsg, [Items[Index]]));
      Appender := ParseAppender(Props, Items[Index]);
      if Assigned(Appender) then
        Cat.AddAppender(Appender);
    end;
  finally
    Items.Free;
  end;
end;

{ Registration ----------------------------------------------------------------}

{ Register a class as an implementor of a particular interface. }
procedure RegisterClass(ClassType: TClass; InterfaceType: TGUID;
  InterfaceName: string; Names: TStringList; Classes: TClassList);
var
  Index: Integer;
begin
  if not Assigned(ClassType.GetInterfaceEntry(InterfaceType)) then
    raise ELogException.Create(Format(InterfaceNotImplMsg,
      [ClassType.ClassName, InterfaceName]));

  Index := Names.IndexOf(ClassType.ClassName);
  if Index = -1 then
  begin
    Names.Add(ClassType.ClassName);
    Classes.Add(ClassType);
  end
  else
    Classes[Index] := ClassType;
end;

{ Create a new instance of a class implementing a particular interface. }
function FindClass(ClassName: string; InterfaceType: TGUID;
  Names: TStringList; Classes: TClassList): IUnknown;
var
  Index: Integer;
  Creator: ILogDynamicCreate;
begin
  if ClassName = '' then
    Exit;

  Index := Names.IndexOf(ClassName);
  if Index = -1 then
  begin
    LogLog.Error(Format(NoClassMsg, [ClassName]));
    Result := nil;
  end
  else
  begin
{$IFDEF VER120}  { Delphi 4 }
    TClass(Classes[Index]).Create.GetInterface(InterfaceType, Result);
{$ELSE}
    Classes[Index].Create.GetInterface(InterfaceType, Result);
{$ENDIF}
    Result.QueryInterface(ILogDynamicCreate, Creator);
    if Assigned(Creator) then
      Creator.Init;
  end;
end;

var
  AppenderNames: TStringList;
  AppenderClasses: TClassList;

procedure RegisterAppender(Appender: TClass);
begin
  RegisterClass(Appender, ILogAppender, 'ILogAppender',
    AppenderNames, AppenderClasses);
end;

function FindAppender(ClassName: string): ILogAppender;
begin
  Result := FindClass(ClassName, ILogAppender, AppenderNames, AppenderClasses)
    as ILogAppender;
end;

var
  CategoryFactoryNames: TStringList;
  CategoryFactoryClasses: TClassList;

procedure RegisterCategoryFactory(CategoryFactory: TClass);
begin
  RegisterClass(CategoryFactory, ILogCategoryFactory, 'ILogCategoryFactory',
    CategoryFactoryNames, CategoryFactoryClasses);
end;

function FindCategoryFactory(ClassName: string): ILogCategoryFactory;
begin
  Result := FindClass(ClassName, ILogCategoryFactory,
    CategoryFactoryNames, CategoryFactoryClasses) as ILogCategoryFactory;
end;

var
  ErrorHandlerNames: TStringList;
  ErrorHandlerClasses: TClassList;

procedure RegisterErrorHandler(ErrorHandler: TClass);
begin
  RegisterClass(ErrorHandler, ILogErrorHandler, 'ILogErrorHandler',
    ErrorHandlerNames, ErrorHandlerClasses);
end;

function FindErrorHandler(ClassName: string): ILogErrorHandler;
begin
  Result := FindClass(ClassName, ILogErrorHandler, ErrorHandlerNames,
    ErrorHandlerClasses) as ILogErrorHandler;
end;

var
  FilterNames: TStringList;
  FilterClasses: TClassList;

procedure RegisterFilter(Filter: TClass);
begin
  RegisterClass(Filter, ILogFilter, 'ILogFilter', FilterNames, FilterClasses);
end;

function FindFilter(ClassName: string): ILogFilter;
begin
  Result := FindClass(ClassName, ILogFilter, FilterNames, FilterClasses)
    as ILogFilter;
end;

var
  LayoutNames: TStringList;
  LayoutClasses: TClassList;

procedure RegisterLayout(Layout: TClass);
begin
  RegisterClass(Layout, ILogLayout, 'ILogLayout', LayoutNames, LayoutClasses);
end;

function FindLayout(ClassName: string): ILogLayout;
begin
  Result := FindClass(ClassName, ILogLayout, LayoutNames, LayoutClasses)
    as ILogLayout;
end;

var
  RenderedNames: TStringList;
  RenderedClasses: TClassList;

{ Register a class to be rendered. }
procedure RegisterRendered(Rendered: TClass);
var
  Index: Integer;
begin
  Index := RenderedNames.IndexOf(Rendered.ClassName);
  if Index = -1 then
  begin
    RenderedNames.Add(Rendered.ClassName);
    RenderedClasses.Add(Rendered);
  end
  else
    RenderedClasses[Index] := Rendered;
end;

{ Return a reference to the named class. }
function FindRendered(ClassName: string): TClass;
var
  Index: Integer;
begin
  Index := RenderedNames.IndexOf(ClassName);
  if Index = -1 then
  begin
    LogLog.Error(Format(NoClassMsg, [ClassName]));
    Result := nil;
  end
  else
{$IFDEF VER120}  { Delphi 4 }
    Result := TClass(RenderedClasses[Index]);
{$ELSE}
    Result := RenderedClasses[Index];
{$ENDIF}
end;

var
  RendererNames: TStringList;
  RendererClasses: TClassList;

procedure RegisterRenderer(Renderer: TClass);
begin
  RegisterClass(Renderer, ILogRenderer, 'ILogRenderer',
    RendererNames, RendererClasses);
end;

function FindRenderer(ClassName: string): ILogRenderer;
begin
  Result := FindClass(ClassName, ILogRenderer,
    RendererNames, RendererClasses) as ILogRenderer;
end;

var
  Index: Integer;
initialization
  { Timestamping. }
  StartTime := Now;
  { Synchronisation. }
  InitializeCriticalSection(CriticalNDC);
  { Standard priorities. }
  Priorities             := TObjectList.Create;
{$IFNDEF VER120}  { Not Delphi 4 }
  Priorities.OwnsObjects := True;
{$ENDIF}
  Debug := TLogPriority.Create('DEBUG', 10000);
  Info  := TLogPriority.Create('INFO',  20000);
  Warn  := TLogPriority.Create('WARN',  30000);
  Error := TLogPriority.Create('ERROR', 40000);
  Fatal := TLogPriority.Create('FATAL', 50000);
  { NDC stack. }
  NDC        := TStringList.Create;
  NDC.Sorted := True;
  { Registration setup. }
  AppenderNames          := TStringList.Create;
  AppenderClasses        := TClassList.Create;
  CategoryFactoryNames   := TStringList.Create;
  CategoryFactoryClasses := TClassList.Create;
  ErrorHandlerNames      := TStringList.Create;
  ErrorHandlerClasses    := TClassList.Create;
  FilterNames            := TStringList.Create;
  FilterClasses          := TClassList.Create;
  LayoutNames            := TStringList.Create;
  LayoutClasses          := TClassList.Create;
  RenderedNames          := TStringList.Create;
  RenderedClasses        := TClassList.Create;
  RendererNames          := TStringList.Create;
  RendererClasses        := TClassList.Create;
  { Registration of standard implementations. }
  RegisterCategoryFactory(TLogDefaultCategoryFactory);
  RegisterErrorHandler(TLogOnlyOnceErrorHandler);
  RegisterLayout(TLogSimpleLayout);
  RegisterLayout(TLogHTMLLayout);
  RegisterLayout(TLogPatternLayout);
  RegisterFilter(TLogStringFilter);
  RegisterAppender(TLogNullAppender);
  RegisterAppender(TLogODSAppender);
  RegisterAppender(TLogStreamAppender);
  RegisterAppender(TLogFileAppender);
  { Standard category factory and hierarchy. }
  DefaultCategoryFactory := TLogDefaultCategoryFactory.Create;
  DefaultCategoryFactory._AddRef;
  DefaultHierarchy       := TLogHierarchy.Create(TLogRoot.Create(Error));
  { Internal logging }
  LogLog           := TLogLog.Create;
  LogLog.Hierarchy := DefaultHierarchy;
finalization
{$IFDEF VER120}  { Delphi 4 }
  for Index := 0 to Priorities.Count - 1 do
    TObject(Priorities[Index]).Free;
{$ENDIF}
  Priorities.Free;
  DefaultCategoryFactory._Release;
  DefaultHierarchy.Free;
  { Registration cleanup. }
  AppenderNames.Free;
  AppenderClasses.Free;
  CategoryFactoryNames.Free;
  CategoryFactoryClasses.Free;
  ErrorHandlerNames.Free;
  ErrorHandlerClasses.Free;
  FilterNames.Free;
  FilterClasses.Free;
  LayoutNames.Free;
  LayoutClasses.Free;
  RenderedNames.Free;
  RenderedClasses.Free;
  RendererNames.Free;
  RendererClasses.Free;
  { NDC. }
  for Index := 0 to NDC.Count - 1 do
    NDC.Objects[Index].Free;
  NDC.Free;
  { Internal logging. }
  LogLog.Free;
  { Synchronisation. }
  DeleteCriticalSection(CriticalNDC);
end.

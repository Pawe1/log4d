unit Log4DXML;

{
  Logging for Delphi - XML support.
  Based on log4j Java package from Apache
  (http://jakarta.apache.org/log4j/docs/index.html).

  XML document layout.
  Configurator from an XML document (uses MSXML v3 for parsing).

  Written by Keith Wood (kbwood@compuserve.com).
  Version 1.0 - 29 April 2001.
}

interface

uses
  Classes, SysUtils, Windows, Log4D, ComObj, ActiveX, MSXML2_tlb;

type
  { This layout outputs events as an XML fragment. }
  TLogXMLLayout = class(TLogCustomLayout)
  protected
    function GetContentType: string; override;
    function GetFooter: string; override;
    function GetHeader: string; override;
  public
    function Format(Event: TLogEvent): string; override;
    function IgnoresException: Boolean; override;
  end;

  { Extends BasicConfigurator to provide configuration from an external XML
    file. See log4d.dtd for the expected format.

    It is sometimes useful to see how Log4D is reading configuration files.
    You can enable Log4D internal logging by defining the debug attribute
    on the log4d:configuration element. }
  TLogXMLConfigurator = class(TLogBasicConfigurator,
    IVBSAXContentHandler, IVBSAXErrorHandler)
  protected
    FAppender: ILogAppender;
    FCategory: TLogCategory;
    FCategoryFactory: ILogCategoryFactory;
    FErrorHandler: ILogErrorHandler;
    FFilter: ILogFilter;
    FHandlers: TInterfaceList;
    FHierarchy: TLogHierarchy;
    FLayout: ILogLayout;
    FLocator: IVBSAXLocator;
  public
    constructor Create;
    destructor Destroy; override;
    class procedure Configure(ConfigURL: string); overload;
    class procedure Configure(Document: TStream); overload;
    procedure DoConfigure(ConfigURL: string; Hierarchy: TLogHierarchy);
      overload;
    procedure DoConfigure(Document: TStream; Hierarchy: TLogHierarchy);
      overload;
    { IVBSAXContentHandler }
{$IFDEF VER140}  { Delphi 6 }
    procedure _Set_documentLocator(const Param1: IVBSAXLocator); safecall;
{$ELSE}
    procedure Set_documentLocator(const Param1: IVBSAXLocator); safecall;
{$ENDIF}
    procedure StartDocument; safecall;
    procedure EndDocument; safecall;
    procedure StartPrefixMapping(var strPrefix: WideString;
      var strURI: WideString); safecall;
    procedure EndPrefixMapping(var strPrefix: WideString); safecall;
    procedure StartElement(var strNamespaceURI: WideString;
      var strLocalName: WideString; var strQName: WideString;
      const oAttributes: IVBSAXAttributes); safecall;
    procedure EndElement(var strNamespaceURI: WideString;
      var strLocalName: WideString; var strQName: WideString); safecall;
    procedure Characters(var strChars: WideString); safecall;
    procedure IgnorableWhitespace(var strChars: WideString); safecall;
    procedure ProcessingInstruction(var strTarget: WideString;
      var strData: WideString); safecall;
    procedure SkippedEntity(var strName: WideString); safecall;
    { IVBSAXErrorHandler }
    procedure Error(const oLocator: IVBSAXLocator;
      var strErrorMessage: WideString; nErrorCode: Integer); safecall;
    procedure FatalError(const oLocator: IVBSAXLocator;
      var strErrorMessage: WideString; nErrorCode: Integer); safecall;
    procedure IgnorableWarning(const oLocator: IVBSAXLocator;
      var strErrorMessage: WideString; nErrorCode: Integer); safecall;
    { IDispatch }
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
      stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
      stdcall;
    { IUnknown }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

const
  { Element and attribute names from the XML configuration document. }
  AdditiveAttr        = 'additive';
  AppenderTag         = 'appender';
  AppenderRefTag      = 'appender-ref';
  CategoryTag         = 'category';
  CategoryFactoryAttr = 'categoryFactory';
  ClassAttr           = 'class';
  ConfigurationTag    = 'log4d:configuration';
  DebugAttr           = 'debug';
  DisableAttr         = 'disable';
  DisableOverrideAttr = 'disableOverride';
  ErrorHandlerTag     = 'errorHandler';
  FilterTag           = 'filter';
  LayoutTag           = 'layout';
  NameAttr            = 'name';
  ParamTag            = 'param';
  PriorityTag         = 'priority';
  RefAttr             = 'ref';
  RendererTag         = 'renderer';
  RenderedClassAttr   = 'renderedClass';
  RenderingClassAttr  = 'renderingClass';
  RootTag             = 'root';
  ValueAttr           = 'value';
  { Element and attribute names from the XML events document. }
  NamespacePrefix     = 'log4d:';
  CategoryAttr        = 'category';
  EventSetTag         = NamespacePrefix + 'eventSet';
  EventTag            = NamespacePrefix + 'event';
  ExceptionTag        = NamespacePrefix + 'exception';
  MessageTag          = NamespacePrefix + 'message';
  NDCTag              = NamespacePrefix + 'NDC';
  PriorityAttr        = 'priority';
  ThreadAttr          = 'thread';
  TimestampAttr       = 'timestamp';

implementation

const
  CRLF = #13#10;

resourcestring
  MessageFormat = '%s during configuration: %s at %d,%d in %s';

var
  s: string;

{ TLogHTMLLayout --------------------------------------------------------------}

{ Write an XML element for each event. }
function TLogXMLLayout.Format(Event: TLogEvent): string;
var
  Value: string;
begin
  Result := '<' + EventTag + ' ' + CategoryAttr + '="' + Event.Category.Name +
    '" ' + PriorityAttr + '="' + Event.Priority.Name +
    '" ' + ThreadAttr + '="' + IntToStr(Event.ThreadId) +
    '" ' + TimestampAttr + '="' + IntToStr(Event.ElapsedTime) +
    '"><' + MessageTag + '>' + Event.Message + '</' + MessageTag + '>';
  Value := Event.NDC;
  if Value <> '' then
    Result := Result + '<' + NDCTag + '>' + Value + '</' + NDCTag + '>';
  Value := Event.ErrorMessage;
  if Value <> '' then
    Result := Result + '<' + ExceptionTag + '>' + Value +
      '</' + ExceptionTag + '>';
  Result := Result + '</' + EventTag + '>' + CRLF;
end;

{ Returns the content type output by this layout, i.e 'text/xml'. }
function TLogXMLLayout.GetContentType: string;
begin
  Result := 'text/xml';
end;

{ Returns appropriate XML closing tags. }
function TLogXMLLayout.GetFooter: string;
begin
  Result := '</' + EventSetTag + '>' + CRLF;
end;

{ Returns appropriate XML opening tags.
  The generated XML is not a complete document, but is intended
  as a well-formed fragment to be included in another XML document. }
function TLogXMLLayout.GetHeader: string;
begin
  Result := '<?xml version="1.0"?>' + CRLF +
    '<!-- DOCTYPE ' + EventSetTag + ' SYSTEM "log4d.dtd" -->' + CRLF +
    '<' + EventSetTag + ' xmlns:' +
    Copy(NamespacePrefix, 1, Length(NamespacePrefix) - 1) +
    '="urn:logging/Log4D">' + CRLF;
end;

{ The XML layout handles the exception contained in logging events.
  Hence, this method return False. }
function TLogXMLLayout.IgnoresException: Boolean;
begin
  Result := False;
end;

{ TLogXMLConfigurator ---------------------------------------------------------}

const
  InternalRootName = 'root';

class procedure TLogXMLConfigurator.Configure(ConfigURL: string);
var
  Config: TLogXMLConfigurator;
begin
  Config := TLogXMLConfigurator.Create;
  try
    Config.DoConfigure(ConfigURL, DefaultHierarchy);
  finally
    Config.Free;
  end;
end;

class procedure TLogXMLConfigurator.Configure(Document: TStream);
var
  Config: TLogXMLConfigurator;
begin
  Config := TLogXMLConfigurator.Create;
  try
    Config.DoConfigure(Document, DefaultHierarchy);
  finally
    Config.Free;
  end;
end;

constructor TLogXMLConfigurator.Create;
begin
  inherited Create;
  FCategoryFactory := TLogDefaultCategoryFactory.Create;
  FHandlers        := TInterfaceList.Create;
end;

destructor TLogXMLConfigurator.Destroy;
begin
  FHandlers.Free;
  inherited Destroy;
end;

procedure TLogXMLConfigurator.DoConfigure(ConfigURL: string;
  Hierarchy: TLogHierarchy);
var
  XMLReader: IVBSAXXMLReader;
begin
  FHierarchy := Hierarchy;
  XMLReader  := CoSAXXMLReader.Create;
{$IFDEF VER140}  { Delphi 6 }
  XMLReader._Set_contentHandler(Self);
  XMLReader._Set_ErrorHandler(Self);
{$ELSE}
  XMLReader.ContentHandler := Self;
  XMLReader.ErrorHandler   := Self;
{$ENDIF}
  XMLReader.ParseURL(ConfigURL);
  LogLog.Debug('Finished configuring - ' + ClassName);
end;

procedure TLogXMLConfigurator.DoConfigure(Document: TStream;
  Hierarchy: TLogHierarchy);
var
  Stream: IStream;
  XMLReader: IVBSAXXMLReader;
begin
  Stream     := TStreamAdapter.Create(Document);
  FHierarchy := Hierarchy;
  XMLReader  := CoSAXXMLReader.Create;
{$IFDEF VER140}  { Delphi 6 }
  XMLReader._Set_ContentHandler(Self);
  XMLReader._Set_ErrorHandler(Self);
{$ELSE}
  XMLReader.ContentHandler := Self;
  XMLReader.ErrorHandler   := Self;
{$ENDIF}
  XMLReader.Parse(Stream);
  LogLog.Debug('Finished configuring - ' + ClassName);
end;

{ IVBSAXContentHandler --------------------------------------------------------}

procedure TLogXMLConfigurator.EndDocument;
begin
  { Do nothing. }
end;

{ Pop current option handler off the stack at the end of the element. }
procedure TLogXMLConfigurator.EndElement(var strNamespaceURI: WideString;
  var strLocalName: WideString; var strQName: WideString);
begin
  if (strQName = AppenderTag) or (strQName = CategoryTag) or
      (strQName = ErrorHandlerTag) or (strQName = FilterTag) or
      (strQName = LayoutTag) or (strQName = RootTag) then
    FHandlers.Delete(FHandlers.Count - 1);
  if (strQName = CategoryTag) or (strQName = RootTag) then
    FCategory.UnlockCategory;
end;

procedure TLogXMLConfigurator.EndPrefixMapping(var strPrefix: WideString);
begin
  { Do nothing. }
end;

procedure TLogXMLConfigurator.Characters(var strChars: WideString);
begin
  { Do nothing. }
end;

procedure TLogXMLConfigurator.IgnorableWhitespace(var strChars: WideString);
begin
  { Do nothing. }
end;

procedure TLogXMLConfigurator.ProcessingInstruction(var strTarget: WideString;
  var strData: WideString);
begin
  { Do nothing. }
end;

{ Save locator for later error reporting. }
{$IFDEF VER140}  { Delphi 6 }
procedure TLogXMLConfigurator._Set_documentLocator(const Param1: IVBSAXLocator);
{$ELSE}
procedure TLogXMLConfigurator.Set_documentLocator(const Param1: IVBSAXLocator);
{$ENDIF}
begin
  FLocator := Param1;
end;

procedure TLogXMLConfigurator.SkippedEntity(var strName: WideString);
begin
  { Do nothing. }
end;

procedure TLogXMLConfigurator.StartDocument;
begin
  FHandlers.Clear;
end;

{ Create new objects as elements are encountered and handle any attributes
  defined for them. }
procedure TLogXMLConfigurator.StartElement(var strNamespaceURI: WideString;
  var strLocalName: WideString; var strQName: WideString;
  const oAttributes: IVBSAXAttributes);
var
  Name: string;

  { Retrieve named attribute, returning an empty string if not there. }
  function GetAttribute(Name: string): string;
  begin
    try
      Result := oAttributes.getValueFromQName(Name);
    except on e: EOleException do
      Result := '';
    end;
  end;

begin
  if strQName = AppenderTag then
  begin
    { New appender. }
    FAppender := FindAppender(GetAttribute(ClassAttr));
    if not Assigned(FAppender) then
      Abort;
    FAppender.Name := GetAttribute(NameAttr);
    AppenderPut(FAppender);
    FHandlers.Add(FAppender);
    LogLog.Debug('Parsed appender ' + FAppender.Name);
  end
  else if strQName = AppenderRefTag then
  begin
    { Reference to an appender for a category. }
    Name      := GetAttribute(RefAttr);
    FAppender := AppenderGet(Name);
    if not Assigned(FAppender) then
      LogLog.Error('Appender "' + Name + '" was not found.')
    else
      FCategory.AddAppender(FAppender);
  end
  else if strQName = CategoryTag then
  begin
    { New category. }
    FCategory          :=
      FHierarchy.GetInstance(GetAttribute(NameAttr), FCategoryFactory);
    FCategory.LockCategory;
    FCategory.Additive := StrToBool(GetAttribute(AdditiveAttr), True);
    (FCategory as ILogOptionHandler)._AddRef;
    FHandlers.Add(FCategory);
    LogLog.Debug('Parsed category ' + FCategory.Name);
  end
  else if strQName = ConfigurationTag then
  begin
    { Global settings. }
    SetGlobalProps(FHierarchy,
      GetAttribute(CategoryFactoryAttr), GetAttribute(DebugAttr),
      GetAttribute(DisableOverrideAttr), GetAttribute(DisableAttr));
  end
  else if strQName = ErrorHandlerTag then
  begin
    { Error handler for an appender. }
    Name                   := GetAttribute(ClassAttr);
    FErrorHandler          := FindErrorHandler(Name);
    FAppender.ErrorHandler := FErrorHandler;
    FHandlers.Add(FErrorHandler);
    LogLog.Debug('Appender ' + FAppender.Name + ' uses error handler ' + Name);
  end
  else if strQName = FilterTag then
  begin
    { New filter for an appender. }
    Name    := GetAttribute(ClassAttr);
    FFilter := FindFilter(Name);
    FAppender.AddFilter(FFilter);
    FHandlers.Add(FFilter);
    LogLog.Debug('Appender ' + FAppender.Name + ' uses filter ' + Name);
  end
  else if strQName = LayoutTag then
  begin
    { Layout for an appender. }
    Name             := GetAttribute(ClassAttr);
    FLayout          := FindLayout(Name);
    FAppender.Layout := FLayout;
    FHandlers.Add(FLayout);
    LogLog.Debug('Appender ' + FAppender.Name + ' uses layout ' + Name);
  end
  else if strQName = ParamTag then
  begin
    { Parameter for an enclosing element (which must be an option handler). }
    ILogOptionHandler(FHandlers.Last).Options[GetAttribute(NameAttr)] :=
      GetAttribute(ValueAttr);
  end
  else if strQName = PriorityTag then
  begin
    { Priority for a category. }
    Name := UpperCase(GetAttribute(ValueAttr));
    if (Name = InheritedPriority) and (FCategory.Name <> InternalRootName) then
      FCategory.Priority := nil
    else
    begin
      FCategory.Priority := GetPriority(Name);
      LogLog.Debug('Category ' + FCategory.Name + ' priority set to ' +
        FCategory.Priority.Name);
    end;
  end
  else if strQName = RendererTag then
  begin
    { Renderer and rendered class. }
    AddRenderer(FHierarchy, GetAttribute(RenderedClassAttr),
      GetAttribute(RenderingClassAttr));
  end
  else if strQName = RootTag then
  begin
    { Configure the root category. }
    FCategory := FHierarchy.Root;
    FCategory.LockCategory;
    (FCategory as ILogOptionHandler)._AddRef;
    FHandlers.Add(FCategory);
    LogLog.Debug('Parsed root category');
  end
end;

procedure TLogXMLConfigurator.StartPrefixMapping(var strPrefix: WideString;
  var strURI: WideString);
begin
  { Do nothing. }
end;

{ IVBSAXErrorHandler ----------------------------------------------------------}

{ Log any errors. }
procedure TLogXMLConfigurator.Error(const oLocator: IVBSAXLocator;
  var strErrorMessage: WideString; nErrorCode: Integer);
begin
  LogLog.Error(Format(MessageFormat, ['Error', strErrorMessage,
    oLocator.LineNumber, oLocator.ColumnNumber, oLocator.SystemId]), nil);
end;

{ Log any fatal errors and abort the configuration process. }
procedure TLogXMLConfigurator.FatalError(const oLocator: IVBSAXLocator;
  var strErrorMessage: WideString; nErrorCode: Integer);
begin
  LogLog.Fatal(Format(MessageFormat, ['Fatal error', strErrorMessage,
    oLocator.LineNumber, oLocator.ColumnNumber, oLocator.SystemId]), nil);
  LogLog.Fatal('Ignoring configuration file.');
  Abort;
end;

{ Log any warnings. }
procedure TLogXMLConfigurator.IgnorableWarning(const oLocator: IVBSAXLocator;
  var strErrorMessage: WideString; nErrorCode: Integer);
begin
  LogLog.Warn(Format(MessageFormat, ['Warning', strErrorMessage,
    oLocator.LineNumber, oLocator.ColumnNumber, oLocator.SystemId]), nil);
end;

{ IDispatch -------------------------------------------------------------------}

{ These functions are required by the IDispatch interface but are not used. }
function TLogXMLConfigurator.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TLogXMLConfigurator.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo):
  HResult;
begin
  Result := E_NOTIMPL;
end;

function TLogXMLConfigurator.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TLogXMLConfigurator.Invoke(DispID: Integer; const IID: TGUID;
  LocaleID: Integer; Flags: Word;
  var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

{ IUnknown --------------------------------------------------------------------}

{ These functions are required by the IUnknown interface but are not used. }
function TLogXMLConfigurator.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE;
end;

function TLogXMLConfigurator._AddRef: Integer;
begin
  Result := 1;
end;

function TLogXMLConfigurator._Release: Integer;
begin
  Result := 1;
end;

initialization
  CoInitialize(nil);
  { Registration of standard implementations. }
  RegisterLayout(TLogXMLLayout);
finalization
  CoUninitialize;
end.

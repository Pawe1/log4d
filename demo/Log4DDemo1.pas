unit Log4DDemo1;

{
  Demonstrate the Log4D package.

  Written by Keith Wood (kbwood@compuserve.com)
}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Log4D, Log4DXML;

type
  TMemoAppender = class(TLogCustomAppender)
  private
    FMemo: TMemo;
  protected
    procedure DoAppend(Message: string); override;
    procedure SetOption(const Name, Value: string); override;
  public
    constructor Create(Name: string; Memo: TMemo); reintroduce; 
  end;

  TComponentRenderer = class(TLogCustomRenderer)
  public
    function Render(Message: TObject): string; override;
  end;

  TfrmLog4DDemo = class(TForm)
    Panel1: TPanel;
      Label1: TLabel;
      cmbPriority: TComboBox;
      Label2: TLabel;
      cmbCategory: TComboBox;
      Label3: TLabel;
      edtMessage: TEdit;
      btnLog: TButton;
      grpFilter: TGroupBox;
        edtFilter: TEdit;
        btnFilter: TButton;
      grpNDC: TGroupBox;
        edtNDC: TEdit;
        btnPush: TButton;
        btnPop: TButton;
      btnLoop: TButton;
    pnlLeft: TPanel;
      lblMyApp: TLabel;
      memMyApp: TMemo;
      splLeft: TSplitter;
      lblMyAppMore: TLabel;
      memMyAppMore: TMemo;
    splVert: TSplitter;
    pnlRight: TPanel;
      lblMyAppOther: TLabel;
      memMyAppOther: TMemo;
      splRight: TSplitter;
      lblAlt: TLabel;
      memAlt: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure btnLogClick(Sender: TObject);
    procedure btnFilterClick(Sender: TObject);
    procedure btnPushClick(Sender: TObject);
    procedure btnPopClick(Sender: TObject);
    procedure btnLoopClick(Sender: TObject);
    procedure splLeftMoved(Sender: TObject);
    procedure splRightMoved(Sender: TObject);
  private
    FFilter: ILogFilter;
    FLogs: array [0..3] of TLogCategory;
  public
  end;

var
  frmLog4DDemo: TfrmLog4DDemo;

implementation

{$R *.DFM}

{$IFNDEF VER120}  { Delphi 4 }
uses
  Contnrs;
{$ENDIF}

{ TMemoAppender ---------------------------------------------------------------}

{ Initialisation - attach to memo. }
constructor TMemoAppender.Create(Name: string; Memo: TMemo);
begin
  inherited Create(Name);
  FMemo := Memo;
end;

{ Add the message to the memo. }
procedure TMemoAppender.DoAppend(Message: string);
begin
  if Assigned(FMemo) and Assigned(FMemo.Parent) then
  begin
    if Copy(Message, Length(Message) - 1, 2) = #13#10 then
      Delete(Message, Length(Message) - 1, 2);
    FMemo.Lines.Add(Message);
  end;
end;

{ Find the named memo and attach to it (if the param is 'memo'). }
procedure TMemoAppender.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if (Name = 'memo') and (Value <> '') then
  begin
    FMemo := frmLog4DDemo.FindComponent(Value) as TMemo;
    WriteHeader;
  end;
end;

{ TComponentRenderer ----------------------------------------------------------}

{ Display a component as its name and type. }
function TComponentRenderer.Render(Message: TObject): string;
var
  Comp: TComponent;
begin
  if not (Message is TComponent) then
    Result := 'Object must be a TComponent'
  else
  begin
    Comp := Message as TComponent;
    if Comp is TControl then
      with TControl(Comp) do
        Result := Format('%s: %s [%d x %d at %d, %d]',
          [Name, ClassName, Width, Height, Left, Top])
    else
      Result := Format('%s: %s', [Comp.Name, Comp.ClassName]);
  end;
end;

{ TfrmLog4DDemo ---------------------------------------------------------------}

{ Initialisation. }
procedure TfrmLog4DDemo.FormCreate(Sender: TObject);
const
  IsAdditive: array [Boolean] of string = ('not ', '');
  Header = ' %s (%sadditive) - %s';
var
  Index: Integer;
  Priorities: TObjectList;
begin
  { Initialise from stored configuration - select between INI style file
    or XML document by uncommenting one of the following two lines. }
//  TLogPropertyConfigurator.Configure('log4d.props');
  TLogXMLConfigurator.Configure('log4d.xml');
  { Create categories for logging - both forms are equivalent. }
  FLogs[0] := DefaultHierarchy.GetInstance('myapp');
  FLogs[1] := TLogCategory.GetInstance('myapp.more');
  FLogs[2] := DefaultHierarchy.GetInstance('myapp.other');
  FLogs[3] := TLogCategory.GetInstance('alt');
  { Show their state on the form. }
  lblMyApp.Caption      := Format(Header,
    [FLogs[0].Name, IsAdditive[FLogs[0].Additive], FLogs[0].Priority.Name]);
  lblMyAppMore.Caption  := Format(Header,
    [FLogs[1].Name, IsAdditive[FLogs[1].Additive], FLogs[1].Priority.Name]);
  lblMyAppOther.Caption := Format(Header,
    [FLogs[2].Name, IsAdditive[FLogs[2].Additive], FLogs[2].Priority.Name]);
  lblAlt.Caption        := Format(Header,
    [FLogs[3].Name, IsAdditive[FLogs[3].Additive], FLogs[3].Priority.Name]);
  { Attach to the filter on the first category. }
  FFilter        := ILogFilter(ILogAppender(FLogs[0].Appenders[0]).Filters[0]);
  edtFilter.Text := FFilter.Options['match'];
  { Load priorities into a combobox. }
  Priorities := GetAllPriorities;
  for Index := 0 to Priorities.Count - 1 do
    with TLogPriority(Priorities[Index]) do
      cmbPriority.Items.AddObject(Name, Pointer(Level));
  cmbPriority.ItemIndex := 0;
  cmbCategory.ItemIndex := 0;
end;

{ Log an event based on user selections. }
procedure TfrmLog4DDemo.btnLogClick(Sender: TObject);
var
  Priority: TLogPriority;
begin
  Priority :=
    GetPriority(Integer(cmbPriority.Items.Objects[cmbPriority.ItemIndex]));
  FLogs[cmbCategory.ItemIndex].Log(Priority, edtMessage.Text);
  FLogs[cmbCategory.ItemIndex].Log(Priority, edtMessage);
end;

{ Apply a new filter value. }
procedure TfrmLog4DDemo.btnFilterClick(Sender: TObject);
begin
  FFilter.Options[MatchOpt] := edtFilter.Text;
end;

{ Add a context entry. }
procedure TfrmLog4DDemo.btnPushClick(Sender: TObject);
begin
  if edtNDC.Text <> '' then
    TLogNDC.Push(edtNDC.Text);
end;

{ Remove a context entry. }
procedure TfrmLog4DDemo.btnPopClick(Sender: TObject);
begin
  TLogNDC.Pop;
end;

{ Sample logging from loop, including error. }
procedure TfrmLog4DDemo.btnLoopClick(Sender: TObject);
var
  Index: Integer;
begin
  try
    for Index := 5 downto 0 do
      FLogs[cmbCategory.ItemIndex].Info(
        Format('%d divided by %d is %g', [3, Index, 3 / Index]));
  except on ex: Exception do
    FLogs[cmbCategory.ItemIndex].Fatal('Error in calculation', ex);
  end;
end;

{ Keep splitters aligned. }
procedure TfrmLog4DDemo.splLeftMoved(Sender: TObject);
begin
  memMyAppOther.Height := memMyApp.Height;
end;

{ Keep splitters aligned. }
procedure TfrmLog4DDemo.splRightMoved(Sender: TObject);
begin
  memMyApp.Height := memMyAppOther.Height;
end;

initialization
  { Register new logging classes. }
  RegisterAppender(TMemoAppender);
  RegisterRendered(TComponent);
  RegisterRenderer(TComponentRenderer);
end.

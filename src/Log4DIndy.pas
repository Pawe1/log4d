unit Log4DIndy;

{
  Logging for Delphi - Internet support.
  Based on log4j Java package from Apache
  (http://jakarta.apache.org/log4j/docs/index.html).

  E-mail appender based on Indy components.

  Written by Keith Wood (kbwood@compuserve.com).
  Version 1.0 - 29 April 2001.
}

interface

uses
  Classes, SysUtils, Log4D, IdSMTP, IdMessage, IdEMailAddress;

const
  { Buffer size option for TLogIndySMTPAppender. }
  BufferSizeOpt = 'bufferSize';
  { From address option for TLogIndySMTPAppender. }
  FromAddrOpt   = 'from';
  { Host option for TLogIndySMTPAppender. }
  HostOpt       = 'host';
  { Password option for TLogIndySMTPAppender. }
  PasswordOpt   = 'password';
  { Port option for TLogIndySMTPAppender. }
  PortOpt       = 'port';
  { Subject option for TLogIndySMTPAppender. }
  SubjectOpt    = 'subject';
  { To address option for TLogIndySMTPAppender. }
  ToAddrOpt     = 'to';
  { User ID option for TLogIndySMTPAppender. }
  UserIDOpt     = 'userID';

type
  { Send messages via e-mail. }
  TLogIndySMTPAppender = class(TLogCustomAppender)
  private
    FBuffer: TStringList;
    FBufferSize: Integer;
    FFromAddr: string;
    FHost: string;
    FPassword: string;
    FPort: Integer;
    FSubject: string;
    FToAddr: string;
    FTrigger: ILogFilter;
    FUserID: string;
  protected
    procedure SetOption(const Name, Value: string); override;
    procedure DoAppend(Event: TLogEvent); overload; override;
    procedure DoAppend(Message: string); overload; override;
  public
    constructor Create(Name, Host: string; Port: Integer;
      UserId, Password, FromAddr, ToAddr, Subject: string;
      Layout: ILogLayout = nil; BufferSize: Integer = 20); virtual;
    destructor Destroy; override;
    property BufferSize: Integer read FBufferSize write FBufferSize;
    property FromAddr: string read FFromAddr write FFromAddr;
    property Host: string read FHost write FHost;
    property Password: string read FPassword write FPassword;
    property Port: Integer read FPort write FPort;
    property Subject: string read FSubject write FSubject;
    property ToAddr: string read FToAddr write FToAddr;
    property Trigger: ILogFilter read FTrigger write FTrigger;
    property UserID: string read FUserID write FUserID;
    procedure Init; override;
  end;

  { Send e-mail only on error message. }
  TLogIndySMTPTrigger = class(TLogCustomFilter)
  public
    function Decide(Event: TLogEvent): TLogFilterDecision; override;
  end;

implementation

resourcestring
  ConvertError = 'Non-numeric value found for %s property "%s" - ignored';

{ TLogIndySMTPAppender --------------------------------------------------------}

{ Initialise properties of the IndySMTP appender. }
constructor TLogIndySMTPAppender.Create(Name, Host: string; Port: Integer;
  UserId, Password, FromAddr, ToAddr, Subject: string;
  Layout: ILogLayout; BufferSize: Integer);
begin
  inherited Create(Name, Layout);
  Self.BufferSize := BufferSize;
  Self.FromAddr   := FromAddr;
  Self.Host       := Host;
  Self.Password   := Password;
  Self.Port       := Port;
  Self.Subject    := Subject;
  Self.ToAddr     := ToAddr;
  Self.UserId     := UserID;
end;

{ Release resources. }
destructor TLogIndySMTPAppender.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

{ Append as usual, then see if e-mail is triggered. }
procedure TLogIndySMTPAppender.DoAppend(Event: TLogEvent);
var
  SMTP: TIdSMTP;
  Message: TIdMessage;
  Body: string;
begin
  inherited DoAppend(Event);
  { An e-mail is only sent when a triggering condition arises.
    When it is sent, the previous BufferSize messages are also sent. }
  if Trigger.Decide(Event) = fdAccept then
  begin
    SMTP    := TIdSMTP.Create(nil);
    Message := TIdMessage.Create(nil);
    Body    := FBuffer.Text;
    FBuffer.Clear;
    try
      try
        SMTP.Host                   := Host;
        if Port <> 0 then
          SMTP.Port                 := Port;
        SMTP.UserId                 := UserID;
        SMTP.Password               := Password;
        Message.From                := TIdEMailAddressItem.Create(nil);
        Message.From.Text           := FromAddr;
        Message.Recipients.Add.Text := ToAddr;
        Message.Subject             := Subject;
        Message.Body.Text           := Body;
        SMTP.Connect;
        SMTP.Send(Message);
        SMTP.Disconnect;
      except on Ex: Exception do
        LogLog.Error('Error during e-mail send - ' + Ex.Message);
      end;
    finally
      SMTP.Free;
      Message.Free;
    end;
  end;
end;

{ Add the new message to the buffer. }
procedure TLogIndySMTPAppender.DoAppend(Message: string);
begin
  while FBuffer.Count > BufferSize do
    FBuffer.Delete(0);
  FBuffer.Add(Message);
end;

{ Initialisation. }
procedure TLogIndySMTPAppender.Init;
begin
  inherited Init;
  FBuffer := TStringList.Create;
  Trigger := TLogIndySMTPTrigger.Create;
end;

{ Set options for this appender. }
procedure TLogIndySMTPAppender.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if Name = BufferSizeOpt then
    try
      BufferSize := StrToInt(Value);
    except
      LogLog.Warn(Format(ConvertError, [BufferSizeOpt, Value]));
    end
  else if Name = FromAddrOpt then
    FromAddr := Value
  else if Name = HostOpt then
    Host := Value
  else if Name = PasswordOpt then
    Password := Value
  else if Name = PortOpt then
    try
      Port := StrToInt(Value);
    except
      LogLog.Warn(Format(ConvertError, [PortOpt, Value]));
    end
  else if Name = SubjectOpt then
    Subject := Value
  else if Name = ToAddrOpt then
    ToAddr := Value
  else if Name = UserIDOpt then
    UserID := Value;
end;

{ TLogIndySMTPTrigger ---------------------------------------------------------}

{ An e-mail is only sent when the priority is Error or greater. }
function TLogIndySMTPTrigger.Decide(Event: TLogEvent): TLogFilterDecision;
begin
  if Event.Priority.IsGreaterOrEqual(Error) then
    Result := fdAccept
  else
    Result := fdDeny;
end;

initialization
  { Registration of standard implementations. }
  RegisterAppender(TLogIndySMTPAppender);
  RegisterFilter(TLogIndySMTPTrigger);
end.

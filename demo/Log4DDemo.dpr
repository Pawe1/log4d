program Log4DDemo;

uses
  Forms,
  Log4DDemo1 in 'Log4DDemo1.pas' {frmLog4DDemo},
  Log4D in 'Log4D.pas',
  Log4DXML in 'Log4DXML.pas',
  Log4DNM in 'Log4DNM.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfrmLog4DDemo, frmLog4DDemo);
  Application.Run;
end.

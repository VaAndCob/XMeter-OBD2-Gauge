program Hex2Const;

uses
  Forms,
  UpdaterTool in 'UpdaterTool.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

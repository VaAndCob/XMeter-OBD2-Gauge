program XMeter10;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Inpout32 in 'UNITS\Inpout32.pas';


{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'X-METER Updater';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

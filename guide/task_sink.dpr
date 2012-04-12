program task_sink;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows, System.SysUtils, zeromq;

procedure Run;
var
  Z: IZeroMQ;
  Receiver: IZMQPair;
  Ticks: Cardinal;
  C: Integer;
  S: string;
begin
  Z := TZeroMQ.Create(1);
  Receiver := Z.Start(ZMQ.Pull);
  Receiver.Bind('tcp://*:5558');

  WriteLn('Waiting for ventilator for start signal...');
  Receiver.ReceiveString;

  WriteLn('Counting finished tasks...');
  Ticks := GetTickCount;
  for C := 0 to 100 - 1 do
  begin
    S := Receiver.ReceiveString;
    if C mod 10 = 0 then
      Write(':')
    else
      Write('.');
  end;
  WriteLn;
  WriteLn('Total elapsed time: ', GetTickCount - Ticks, 'ms');
end;

begin
  try
    Run;
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

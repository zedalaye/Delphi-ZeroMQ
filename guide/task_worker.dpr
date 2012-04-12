program task_worker;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, zeromq;

procedure Run;
var
  Z: IZeroMQ;
  Receiver: IZMQPair;
  Sender: IZMQPair;
  S: string;
begin
  Z := TZeroMQ.Create(1);
  Receiver := Z.Start(ZMQ.Pull);
  Receiver.Connect('tcp://localhost:5557');

  Sender := Z.Start(ZMQ.Push);
  Sender.Connect('tcp://localhost:5558');

  while True do
  begin
    S := Receiver.ReceiveString;
    Writeln(S);
    Sleep(StrToInt(S));
    Sender.SendString('');
  end;
end;

begin
  try
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

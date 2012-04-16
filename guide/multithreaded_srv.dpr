program multithreaded_srv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.Classes, ZeroMQ.Wrapper;

type
  TWorkerThread = class(TThread)
  private
    FContext: IZeroMQ;
  protected
    procedure Execute; override;
  public
    constructor Create(Context: IZeroMQ);
  end;

{ TWorkerThread }

constructor TWorkerThread.Create(Context: IZeroMQ);
begin
  inherited Create(False);
  FContext := Context;
  FreeOnTerminate := True;
end;

procedure TWorkerThread.Execute;
var
  Receiver: IZMQPair;
  Request: string;
begin
  Receiver := FContext.Start(ZMQ.Responder);
  Receiver.Connect('inproc://workers');

  while not Terminated do
  begin
    Request := Receiver.ReceiveString;
    WriteLn('Received request: [', Request, ']');
    Sleep(1);
    Receiver.SendString('World');
  end;
end;

procedure Run;
var
  Z: IZeroMQ;
  Clients, Workers: IZMQPair;
  ThreadsCount: Integer;
begin
  Z := TZeroMQ.Create;
  Clients := Z.Start(ZMQ.Router);
  Clients.Bind('tcp://*:5555');

  Workers := Z.Start(ZMQ.Dealer);
  Workers.Bind('inproc://workers');

  for ThreadsCount := 0 to 5 - 1 do
    TWorkerThread.Create(Z);

  Z.StartDevice(ZMQDevice.Queue, Clients, Workers);
end;

begin
  try
    IsMultiThread := True;
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

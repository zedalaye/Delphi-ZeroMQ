program weather_srv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, ZeroMQ;

procedure Run;
var
  Z: IZeroMQ;
  P: IZMQPair;
  zipcode, temperature, relhumidity: Integer;
  update: string;
begin
  Z := TZeroMQ.Create;
  P := Z.Start(ZMQSocket.Publisher);
  P.Bind('tcp://*:5556');
  Writeln('Started weather server (TCP/5556)...');

  while True do
  begin
    // Get values that will fool the boss
    zipcode     := Random(100000);
    temperature := Random(215) - 80;
    relhumidity := Random(50) + 10;

    // Send message to all subscribers
    update := Format('%05d %d %d', [zipcode, temperature, relhumidity]);
    P.SendString(update);
  end;
end;

begin
  try
    Randomize;
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

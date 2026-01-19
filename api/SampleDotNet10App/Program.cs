using System.Diagnostics;

Console.WriteLine("🚀 Hello from .NET 10!");

var stopwatch = Stopwatch.StartNew();
await Task.Delay(500);
stopwatch.Stop();

Console.WriteLine($"Execution time: {stopwatch.ElapsedMilliseconds} ms");

// Example of modern pattern usage
int number = Random.Shared.Next(1, 100);

string result = number switch
{
    < 50 => "Less than 50",
    50 => "Exactly 50",
    > 50 => "Greater than 50"
};
//comment for test-1.0.1
//comment for test-1.0.2
//comment for test-1.0.3
//comment for test-1.0.4
//comment for test-1.0.5
//comment for test-1.0.6
Console.WriteLine($"Number1: {number} → {result}");
Console.WriteLine($"Number: {number} → {result}");
Console.WriteLine($"Number2: {number} → {result}");
Console.WriteLine($"Number3: {number} → {result}");

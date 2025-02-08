using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Confluent.Kafka;

class KafkaConsumerExample
{
    static async Task Main(string[] args)
    {
        // Kafka consumer configuration
        var conf = new ConsumerConfig
        {
            GroupId = "hdfs-consumer-group",
            BootstrapServers = "192.168.56.12:9092", // Kafka broker address
            AutoOffsetReset = AutoOffsetReset.Earliest,
            EnableAutoCommit = false // Disable auto-commit for manual control
        };

        // HDFS WebHDFS URL
        string hdfsUrl = "http://192.168.56.14:9870/webhdfs/v1/logs/nginx.log?op=APPEND&user.name=hadoop";

        using (var consumer = new ConsumerBuilder<Ignore, string>(conf).Build())
        {
            consumer.Subscribe("nginx-logs");

            Console.WriteLine("Consuming messages from Kafka in real-time...");
            while (true)
            {
                try
                {
                    // Poll for new messages
                    var consumeResult = consumer.Consume();

                    // Extract the message value
                    string message = consumeResult.Message.Value;
                    Console.WriteLine($"Received message: {message}");

                    // Write the message to HDFS asynchronously
                    await WriteToHDFS(hdfsUrl, message);

                    // Commit the offset manually
                    consumer.Commit(consumeResult);
                }
                catch (ConsumeException e)
                {
                    Console.WriteLine($"Error occurred: {e.Error.Reason}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Unexpected error: {ex.Message}");
                }
            }
        }
    }

    static async Task WriteToHDFS(string hdfsUrl, string message)
    {
        try
        {
            // Use HttpClient to send a POST request to WebHDFS
            using (var client = new HttpClient())
            {
                var content = new StringContent(message, Encoding.UTF8, "application/octet-stream");
                HttpResponseMessage response = await client.PostAsync(hdfsUrl, content);

                if (response.IsSuccessStatusCode)
                {
                    Console.WriteLine("Message written to HDFS successfully.");
                }
                else
                {
                    Console.WriteLine($"Failed to write to HDFS. Status Code: {response.StatusCode}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error writing to HDFS: {ex.Message}");
        }
    }
}
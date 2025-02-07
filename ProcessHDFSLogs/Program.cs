using System;
using System.Data.SqlClient;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;  // For JSON parsing
using System.Threading.Tasks;
using Serilog;  // For logging (make sure to install Serilog NuGet package)

class NginxLogProcessor
{
    static async Task Main(string[] args)
    {
        // Initialize logging
        Log.Logger = new LoggerConfiguration()
            .WriteTo.Console()
            .WriteTo.File("nginx_log_processor.txt", rollingInterval: RollingInterval.Day)
            .CreateLogger();

        try
        {
            // Step 1: Fetch Nginx Logs from HDFS (WebHDFS API)
            string hdfsUrl = "http://192.168.56.13:9870/webhdfs/v1/logs/nginx_logs.txt?op=OPEN&user.name=hadoop";
            string logContent = await FetchLogsFromHDFS(hdfsUrl);
            if (logContent == null)
            {
                Log.Error("Failed to fetch logs from HDFS.");
                return;
            }

            Log.Information("Fetched logs successfully from HDFS.");

            // Step 2: Process Nginx Logs
            var processedLogs = ProcessLogs(logContent);
            Log.Information("Processed logs successfully.");
            Log.Information(processedLogs);

            // Step 3: Store Processed Data into SQL Database
            string connectionString = "Server=192.168.56.13;Database=nginx_logs_db;User Id=your_username;Password=your_password;";
            // await StoreLogsInDatabase(processedLogs, connectionString);
            // Log.Information("Logs stored successfully in SQL database.");
        }
        catch (Exception ex)
        {
            Log.Error($"An error occurred: {ex.Message}");
        }
        finally
        {
            Log.CloseAndFlush();
        }
    }

    // Method to fetch logs from HDFS
    static async Task<string> FetchLogsFromHDFS(string hdfsUrl)
    {
        using (var client = new HttpClient())
        {
            try
            {
                HttpResponseMessage response = await client.GetAsync(hdfsUrl);
                if (response.IsSuccessStatusCode)
                {
                    return await response.Content.ReadAsStringAsync();
                }
                else
                {
                    Log.Error($"Failed to fetch logs from HDFS. Status Code: {response.StatusCode}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                Log.Error($"Error while fetching logs from HDFS: {ex.Message}");
                return null;
            }
        }
    }

    // Method to process Nginx logs (extracted from the JSON format)
    static string ProcessLogs(string logContent)
    {
        try
        {
            var processedLogs = new StringBuilder();
            var logs = logContent.Split('\n');

            // Process each log entry (JSON format)
            foreach (var log in logs)
            {
                if (!string.IsNullOrWhiteSpace(log))
                {
                    try
                    {
                        // Attempt to deserialize each log entry as a JSON object
                        JsonElement logData;
                        try
                        {
                            logData = JsonSerializer.Deserialize<JsonElement>(log);
                        }
                        catch (JsonException jsonEx)
                        {
                            Log.Warning($"Skipping invalid log entry: {log}. Error: {jsonEx.Message}");
                            continue;  // Skip this log entry if it is invalid JSON
                        }

                        // Extract fields from the JSON object
                        var timestamp = logData.GetProperty("@timestamp").GetString();
                        var message = logData.GetProperty("message").GetString();
                        var ip = message.Split(' ')[0];  // Extract IP from the Nginx log message
                        var request = ExtractRequest(message);
                        var statusCode = ExtractStatusCode(message);
                        var referrer = ExtractReferrer(message);
                        var userAgent = ExtractUserAgent(message);

                        // Print extracted fields to console
                        processedLogs.AppendLine($"Timestamp: {timestamp}, IP: {ip}, Request: {request}, Status: {statusCode}, Referrer: {referrer}, User-Agent: {userAgent}");
                    }
                    catch (Exception ex)
                    {
                        Log.Error($"Error processing log entry: {ex.Message}");
                    }
                }
            }
            return processedLogs.ToString();
        }
        catch (Exception ex)
        {
            Log.Error($"Error processing logs: {ex.Message}");
            return null;
        }
    }

    // Method to extract request from the Nginx log message
    static string ExtractRequest(string logMessage)
    {
        var parts = logMessage.Split('"');
        return parts.Length > 1 ? parts[1] : "N/A";
    }

    // Method to extract status code from the Nginx log message
    static string ExtractStatusCode(string logMessage)
    {
        var parts = logMessage.Split(' ');
        return parts.Length > 8 ? parts[8] : "N/A";
    }

    // Method to extract referrer from the Nginx log message
    static string ExtractReferrer(string logMessage)
    {
        var parts = logMessage.Split('"');
        return parts.Length > 3 ? parts[3] : "N/A";
    }

    // Method to extract user-agent from the Nginx log message
    static string ExtractUserAgent(string logMessage)
    {
        var parts = logMessage.Split('"');
        return parts.Length > 5 ? parts[5] : "N/A";
    }

    // Method to store processed logs into SQL database
    static async Task StoreLogsInDatabase(string processedLogs, string connectionString)
    {
        if (string.IsNullOrEmpty(processedLogs)) return;

        using (var connection = new SqlConnection(connectionString))
        {
            await connection.OpenAsync();
            using (var transaction = connection.BeginTransaction())
            {
                try
                {
                    foreach (var log in processedLogs.Split('\n'))
                    {
                        if (!string.IsNullOrWhiteSpace(log))
                        {
                            var command = new SqlCommand("INSERT INTO NginxLogs (LogData) VALUES (@LogData)", connection, transaction);
                            command.Parameters.AddWithValue("@LogData", log);
                            await command.ExecuteNonQueryAsync();
                        }
                    }
                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    Log.Error($"Error storing logs in database: {ex.Message}");
                }
            }
        }
    }
}

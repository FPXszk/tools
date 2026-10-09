
# ==========================================
# War Dogs Auto Clicker
# ==========================================

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WarDogsMouse
{
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int key);

    [DllImport("user32.dll")]
    public static extern void mouse_event(
        uint flags,
        uint dx,
        uint dy,
        uint data,
        UIntPtr extraInfo
    );

    public const uint LEFTDOWN = 0x0002;
    public const uint LEFTUP = 0x0004;
}
"@

# ==========================================
# Settings
# ==========================================

$processName = "WardogsClient-Win64-Shipping"

# Mouse timing
$holdTime = 500
$releaseTime = 100

# Start delay
$startDelay = 1000

# ==========================================
# Find War Dogs
# ==========================================

$game = Get-Process -Name $processName -ErrorAction SilentlyContinue |
    Where-Object {
        $_.MainWindowHandle -ne 0
    } |
    Select-Object -First 1

if ($null -eq $game) {
    Write-Host "ERROR: War Dogs is not running."
    exit
}

$targetHandle = $game.MainWindowHandle

Write-Host "War Dogs found."
Write-Host "PID: $($game.Id)"

# ==========================================
# Activate War Dogs
# ==========================================

[WarDogsMouse]::SetForegroundWindow(
    $targetHandle
) | Out-Null

Start-Sleep -Milliseconds 100

$activeHandle = [WarDogsMouse]::GetForegroundWindow()

if ($activeHandle -ne $targetHandle) {
    Write-Host "ERROR: Failed to activate War Dogs."
    exit
}

Write-Host "War Dogs activated."
Write-Host "Starting in 1 second..."
Write-Host "Press ESC to stop."

# ==========================================
# Start delay
# ==========================================

Start-Sleep -Milliseconds $startDelay

# ==========================================
# Auto click
# ==========================================

$clickCount = 0
$stopRequested = $false
$mouseDown = $false

try {

    while (-not $stopRequested) {

        # Stop with ESC
        if ([WarDogsMouse]::GetAsyncKeyState(0x1B) -lt 0) {
            Write-Host "ESC detected."
            break
        }

        # Stop when War Dogs loses focus
        $activeHandle = [WarDogsMouse]::GetForegroundWindow()

        if ($activeHandle -ne $targetHandle) {
            Write-Host "War Dogs lost focus."
            break
        }

        # Left mouse button DOWN
        [WarDogsMouse]::mouse_event(
            [WarDogsMouse]::LEFTDOWN,
            0, 0, 0,
            [UIntPtr]::Zero
        )

        $mouseDown = $true

        # Hold for 300ms
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        while ($timer.ElapsedMilliseconds -lt $holdTime) {

            # Check ESC during hold
            if ([WarDogsMouse]::GetAsyncKeyState(0x1B) -lt 0) {
                $stopRequested = $true
                break
            }

            # Check game focus during hold
            if ([WarDogsMouse]::GetForegroundWindow() -ne $targetHandle) {
                $stopRequested = $true
                break
            }

            Start-Sleep -Milliseconds 10
        }

        $timer.Stop()

        # Left mouse button UP
        [WarDogsMouse]::mouse_event(
            [WarDogsMouse]::LEFTUP,
            0, 0, 0,
            [UIntPtr]::Zero
        )

        $mouseDown = $false

        if ($stopRequested) {
            break
        }

        $clickCount++

        # Release for 10ms
        Start-Sleep -Milliseconds $releaseTime

    }

}
finally {

    # Always release mouse button
    if ($mouseDown) {

        [WarDogsMouse]::mouse_event(
            [WarDogsMouse]::LEFTUP,
            0, 0, 0,
            [UIntPtr]::Zero
        )

    }

    Write-Host ""
    Write-Host "Auto click stopped."
    Write-Host "Total clicks: $clickCount"

}
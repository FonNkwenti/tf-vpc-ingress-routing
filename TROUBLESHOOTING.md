# Troubleshooting Connectivity

If you cannot reach the Application Server through the Inspection Instance (e.g., pings or curl timeout), follow this guide to diagnose the issue.

## Scenario
*   **Application Public IP**: Unreachable (Timeout).
*   **Inspection Public IP**: Reachable (Ping works).
*   **Routing**: Traffic to App Server is routed via Inspection Instance.

## Diagnosis Steps

The most effective way to troubleshoot network flows is to see *where* the packet stops. We will use `tcpdump` on the inspection instance.

1.  **SSH into the Inspection Instance**:
    Use the `inspection_public_ip` output from Terraform.
    ```bash
    ssh -i <your-key>.pem ec2-user@<inspection_public_ip>
    ```

2.  **Start Inspection (Packet Capture)**:
    Run `tcpdump` to listen for ICMP (ping) packets.
    ```bash
    sudo tcpdump -n icmp
    ```

3.  **Generate Traffic**:
    From your local machine (in a separate terminal), attempt to ping the **Application Server**.
    ```bash
    ping <application_public_ip>
    ```

## Interpreting Results

### Case A: Packets DO NOT appear in tcpdump
If you send pings but **see nothing** on the inspection instance console:
*   **Cause**: AWS Networking dropped the packet *before* delivering it to the instance's network interface.
*   **Reason**: **Source/Destination Checks are Enabled**. EC2 instances drop traffic not destined for their own IP address unless this check is disabled.
*   **Fix**: Set `source_dest_check = false` in your Terraform configuration.

### Case B: Packets appear but no reply
If you see `"IP <your-ip> > <app-ip>: ICMP echo request"`, but no reply:
*   **Cause**: The instance received the packet but didn't forward it.
*   **Reason**: IP Forwarding might be disabled in the OS.
*   **Fix**: Ensure `sysctl -w net.ipv4.ip_forward=1` was run (checked in `user_data` script).

### Case C: Packets appear, forwarded, but still no reply
If you see request AND reply, but the reply doesn't reach you:
*   **Cause**: Return routing issue.
*   **Reason**: Does the Application Server know to send traffic back through the Inspection Instance? (Route Tables).

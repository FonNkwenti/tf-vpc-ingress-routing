# Troubleshooting Connectivity

If you cannot reach the Application Server through the Inspection Instance (e.g., pings or curl timeout), follow this guide to diagnose the issue.

## Scenario
*   **Application Public IP**: Unreachable (Timeout).
*   **Inspection Public IP**: Reachable (Ping works).
*   **Routing**: Traffic to App Server is routed via Inspection Instance.

## Verification: Identifying Forwarding

To confirm that the Inspection Instance is actively forwarding traffic, you need to see the packet enter **AND** leave the interface.

1.  **SSH into the Inspection Instance**:
    ```bash
    ssh -i <your-key>.pem ec2-user@<inspection_public_ip>
    ```

2.  **Run `tcpdump` filtered on the App's PRIVATE IP**:
    Find the application's private IP (e.g., `10.0.100.x`).
    ```bash
    sudo tcpdump -n host <application_private_ip>
    ```

3.  **Generate Traffic**:
    From your laptop, ping the **Application Public IP**.

4.  **Analyze the Output**:
    If forwarding is working, you will see pairs of packets for every request:
    *   **Inbound**: `IP <client_ip> > <app_private_ip>: ICMP echo request` (Arriving at inspection)
    *   **Outbound**: `IP <client_ip> > <app_private_ip>: ICMP echo request` (Leaving inspection towards App)
    
    *If you only see the Inbound packet, the instance is dropping it (Source/Dest check or firewall).*

---

## FAQ

### Does the Application Instance need a Public IP?
**Yes.**

Even though the traffic is routed through the Inspection Instance:
1.  **Client Destination**: Your laptop sends packets to a specific Public IP address.
2.  **IGW Translation**: The Internet Gateway (IGW) maintains the 1:1 NAT mapping between that Public IP and the instance's Private IP.
3.  **Ingress Routing**: When the packet arrives at the IGW, the "Edge Route Table" intercepts it. However, the IGW first needs to know *which* instance the destination Public IP belongs to.

If the instance does not have a Public IP (or EIP), the IGW will simply drop the inbound traffic because there is no destination to map it to.

---

## Diagnosis Steps (For Broken Connectivity)

The most effective way to troubleshoot network flows is to see *where* the packet stops. We will use `tcpdump` on the inspection instance.

1.  **SSH into the Inspection Instance**.
2.  **Start Inspection**: `sudo tcpdump -n icmp`
3.  **Generate Traffic**: Ping the Application Server.

### Interpreting Results

#### Case A: Packets DO NOT appear in tcpdump
*   **Cause**: AWS Networking dropped the packet *before* delivering it to the instance's network interface.
*   **Reason**: **Source/Destination Checks are Enabled**.
*   **Fix**: Set `source_dest_check = false` in your Terraform configuration.

#### Case B: Packets appear but no reply
*   **Cause**: The instance received the packet but didn't forward it.
*   **Reason**: IP Forwarding might be disabled in the OS.
*   **Fix**: Ensure `sysctl -w net.ipv4.ip_forward=1` was run (checked in `user_data` script).

#### Case C: Packets appear, forwarded, but still no reply
*   **Cause**: Return routing issue.
*   **Reason**: Does the Application Server know to send traffic back through the Inspection Instance? The Application Subnet must have a route `0.0.0.0/0 -> Inspection ENI`.

/*
 * SPDX-License-Identifier: GPL-2.0-only
 */

#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/internet-module.h"
#include "ns3/network-module.h"
#include "ns3/point-to-point-module.h"

// Default Network Topology
//
//       10.1.1.0
// n0 -------------- n1
//    point-to-point
//

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("FirstScriptExample");

int
main(int argc, char* argv[])
{
    CommandLine cmd(__FILE__);
    cmd.Parse(argc, argv);

    Time::SetResolution(Time::NS); // nanosec porjnto precision chai
    LogComponentEnable("UdpEchoClientApplication", LOG_LEVEL_INFO);
    LogComponentEnable("UdpEchoServerApplication", LOG_LEVEL_INFO);
    // enabling the log component for client and server applications with info level
    NodeContainer nodes;
    nodes.Create(2);
    // node container banailam 2 nodes er jonno

    PointToPointHelper pointToPoint; // topolpgy set
    pointToPoint.SetDeviceAttribute("DataRate", StringValue("5Mbps"));
    // koto data rate hobe seta set korlam
    pointToPoint.SetChannelAttribute("Delay", StringValue("2ms"));

    NetDeviceContainer devices;
    devices = pointToPoint.Install(nodes);

    InternetStackHelper stack;
    stack.Install(nodes);

    Ipv4AddressHelper address;
    address.SetBase("10.1.1.0", "255.255.255.0"); // network address and subnet mask set

    Ipv4InterfaceContainer interfaces = address.Assign(devices);
    // ip address assign korlam devices gulate ( in 2 devices )

    UdpEchoServerHelper echoServer(9); // server application create//port 9

    ApplicationContainer serverApps = echoServer.Install(nodes.Get(1));
    // get(1) means second node ke choose & server banailam here
    serverApps.Start(Seconds(1));
    serverApps.Stop(Seconds(10));

    // client application create
    UdpEchoClientHelper echoClient(interfaces.GetAddress(1), 9);
    echoClient.SetAttribute("MaxPackets", UintegerValue(1));
    // koeta packet pathabe seta set korlam
    echoClient.SetAttribute("Interval", TimeValue(Seconds(1)));
    // kotokkhon por por packet pathabe seta set korlam
    echoClient.SetAttribute("PacketSize", UintegerValue(1024));
    // packet er size set korlam

    ApplicationContainer clientApps = echoClient.Install(nodes.Get(0));
    // first node ke client banailam ekhane
    clientApps.Start(Seconds(2)); // later than server ( bcz we need server first )
    clientApps.Stop(Seconds(10));

    AsciiTraceHelper ascii;

    pointToPoint.EnableAsciiAll(ascii.CreateFileStream("scratch/first/first.tr"));

    pointToPoint.EnablePcapAll("scratch/first/first");

    // simulation run
    Simulator::Run();
    Simulator::Destroy();
    return 0;
}

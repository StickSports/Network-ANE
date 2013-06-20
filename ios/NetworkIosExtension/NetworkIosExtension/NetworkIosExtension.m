//
//  NetworkIosExtension.m
//  NetworkIosExtension
//
//  Created by Richard Lord on 05/02/2013.
//  Copyright (c) 2013 Stick Sports. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"
#include <stdio.h>
#include <sys/types.h>
#include <ifaddrs.h>
#include <netinet/in.h>
#include <string.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <sys/sockio.h>
#include <sys/ioctl.h>
#include <netdb.h>
#include <sys/sysctl.h>
#include <net/ethernet.h>
#include <net/if_dl.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#import <SystemConfiguration/SCNetworkReachability.h>

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

void * tmpAddrPtr = NULL;
void * tmpbroadPtr = NULL;
char * iPVersion = "IPV4";
int PrefixLength = -1;
struct ifreq ifr;

// InterfaceAddrsArray is used as a working variable in getInterfaceProperties()

FREObject InterfaceAddrsArray[4];

// A NetworkInterfaceArray object contains these array elements:
//
// - The name of the network interface.
// - The display name of the network interface. (The same as the interface name in this implementation.)
// - The maximum transmission unit (MTU) of the network interface.
// - The status of the network interface -- whether the interface is active.
// - The hardware address of this network interface.
// - InterfacePropArray


FREObject NetworkInterfaceArray[6];


// An InterfacePropArray object contains these Array elements:
//
// - The Internet Protocol (IP) address.
// - The broadcast address of the local network segment.
// - The prefix length for the address.
// - The IP address type (IPv4 or IPv6).

FREObject InterfacePropArray = NULL ;

FREObject getInterfaceProperties(struct ifaddrs *ifa);

DEFINE_ANE_FUNCTION( findInterfaces )
{
    NSLog(@"Entering findInterfaces()");
    
	struct ifaddrs * ifAddrStruct = NULL;
	struct ifaddrs * ifa = NULL;
	BOOL flag = FALSE;
	
    
    FREObject tempNetworkInterface = NULL;
	FREObject returnInterfacesArray = NULL ;
	
	char * InterfaceName = "";
	char *INamehw = "";
	getifaddrs(&ifAddrStruct);
	
	
	const struct sockaddr_dl * dlAddr;
	const unsigned char* base;
	int hwindex;
	char* macAddress= (char*)malloc(18);
	
	FRENewObject((const uint8_t*)"Array", 0, NULL, &returnInterfacesArray, nil);
	FRENewObject((const uint8_t*)"Array", 0, NULL, &InterfacePropArray, nil);
	
    int i = 0, j = 0;
    
    // Process each interface address returned from getifaddrs().
	
	for (ifa = ifAddrStruct; ifa != NULL; ifa = ifa->ifa_next)
	{
		
		if ( ifa->ifa_addr->sa_family == AF_LINK )
		{
            //  Find the hardware address
			
			dlAddr = (const struct sockaddr_dl *) ifa->ifa_addr;
			base = (const unsigned char*) &dlAddr->sdl_data[dlAddr->sdl_nlen];
			strcpy(macAddress, "");
            
			for (hwindex = 0; hwindex < dlAddr->sdl_alen; hwindex++) {
				
				if (hwindex != 0) {
					strcat(macAddress, ":");
				}
                
				char partialAddr[3];
				sprintf(partialAddr, "%02X", base[hwindex]);
				strcat(macAddress, partialAddr);
				
			}
            
			INamehw = ifa->ifa_name;
			
		}
		
		
        // When iterating through the list of interface address structures provided by getifaddrs(),
        // each interface name gets repeated at least twice with a different family type.
        
        // Determine if the interface name is a repeat of the the previous interface name.
		
        int cmp = strcmp(InterfaceName, (const char*)(ifa->ifa_name));
		
        
        if (cmp != 0 )
			
        {
            // This is the first occurence of the name.
			
            
            InterfaceName = ifa->ifa_name;
			
            // Determine if this is a valid Link Local Interface. If it is, InterfaceName and INamehw
            // have been set to the same value.
			
            if (strcmp(InterfaceName, INamehw) == 0)
            {
                // Add this interface hardware address to the actionscript array element
				
                FRENewObjectFromUTF8(32, (const uint8_t*)macAddress, &NetworkInterfaceArray[4]);
				
            }
			
            if (flag)
            {
				
                // flag is initially false, and set to true after the first iteration through for-loop.
                // Therefore, this code is executed one time for each different Interface name.
                
                // This code puts a new NetworkInterface object in the array of returned NetworkInterface
                // objects, and does reinitialization to prepare for the next name in the for-loop.
                
                
				
                // Assign InterfacePropArray to the NetworkInterfaceArray
                NetworkInterfaceArray[5] = InterfacePropArray;
                j = 0;
				
				
                //Create a new object of class NetworkInterface
				
                FRENewObject(
                             (const uint8_t*)"com.sticksports.nativeExtensions.network.TempNetworkInterface",
                             6,
                             NetworkInterfaceArray,
                             &tempNetworkInterface,
                             nil
                             );
				
                // Put the new FREObject into the returnInterfacesArray
				
                FRESetArrayElementAt(returnInterfacesArray, i++, tempNetworkInterface);
				
				
                // Reinstantiate the InterfaceProperty Array
                FRENewObject((const uint8_t*)"Array", 0, NULL, &InterfacePropArray, nil);
				
                // Clearing the NetworkInterfaceArray
				
                for (int index = 0; index<=5;index++)
                {
                    NetworkInterfaceArray[index] = nil;
                }
				
            }
			
			
            flag = TRUE;
			
			
            // Add the interface name to the NetworkInterfaceArray
			
            FRENewObjectFromUTF8(strlen(ifa->ifa_name), (const uint8_t*)ifa->ifa_name, &NetworkInterfaceArray[0]);
			
            // Add the display Name to the NetworkInterfaceArray. For this implementation, the display name
            // is the same as the interface name.
			
            FRENewObjectFromUTF8(strlen(ifa->ifa_name), (const uint8_t*)ifa->ifa_name, &NetworkInterfaceArray[1]);
			
            // Create a dummy socket to fetch  mtu using ioctl calls
			
            int s = socket(AF_INET,SOCK_DGRAM, 0);
			
            if (s != -1)
            {
                struct ifreq ifr ;
                memset( &ifr, 0, sizeof(ifr));
                strcpy(ifr.ifr_name, ifa->ifa_name);
				
                //Ioctl Call to find MTU
                if (ioctl(s,SIOCGIFMTU, (caddr_t) &ifr) >= 0)
                {
                    NSLog(@"findInterfaces(): MTU: %d", ifr.ifr_mtu);
                    FRENewObjectFromInt32(ifr.ifr_mtu, &NetworkInterfaceArray[2]);
					
                }
				
                close(s);
            }
			
        }  // end if interface name is not a repeat
		
		
		
		NSLog(@"+++++++++++++++++++++++++++++++++++++++++++To trace j (): Before Interface Properties for interface name %s and value of j is %d",ifa->ifa_name,j );
        
        // Each interface can have more than one element in its InterfacePropArray array.
        // This relationship corresponds to how on the ActionScript side, a NetworkInterface object
        // contains a vector of InterfaceAddress objects.
        
        FRESetArrayElementAt(InterfacePropArray, j, getInterfaceProperties(ifa));
        if (ifa->ifa_addr->sa_family == AF_INET || ifa->ifa_addr->sa_family == AF_INET6 )
        {
			j++;
        }
        else
        {
            // Reinstantiate the InterfaceProperty Array
            FRENewObject((const uint8_t*)"Array", 0, NULL, &InterfacePropArray, NULL);
        }
		
		
	} // end for-loop
	
	
	
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++all the interfaces has been iterated +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	NSLog(@" ++++++++++++++++++++++++++++++++++++++++++++++++++Exiting FOR LOOP and pushing array for last time ++++++++++");
	
	
	// Assign InterfacePropArray to the NetworkInterfaceArray
	NetworkInterfaceArray[5] = InterfacePropArray;
	
	
	//Create a new object of class NetworkInterface
	
	FRENewObject(
				 (const uint8_t*)"com.sticksports.nativeExtensions.network.TempNetworkInterface",
				 6,
				 NetworkInterfaceArray,
                 &tempNetworkInterface,
				 nil
				 );
	
	// Put the new FREObject into the returnInterfacesArray
	
    FRESetArrayElementAt(returnInterfacesArray, i++, tempNetworkInterface);
	
	
	// Reinstantiate the InterfaceProperty Array
	FRENewObject((const uint8_t*)"Array", 0, NULL, &InterfacePropArray, NULL);
	
	//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	if (ifAddrStruct != NULL)  freeifaddrs(ifAddrStruct);
    
    NSLog(@"Exiting findInterfaces()");
    
	// Return returnInterfacesArray to ActionScript Code
    return returnInterfacesArray;
}




// getInterfaceProperties()
//
// Finds properties of an interface address.  findInterfaces() calls this method for each interface.

FREObject getInterfaceProperties(struct ifaddrs *ifa)
{
    NSLog(@"Entering getInterfaceProperties()");
	
	FREObject Addrstemp = nil;
	BOOL state = FALSE;
	
	if (ifa ->ifa_addr->sa_family == AF_INET)
	{
		
		// If the address is a valid IP4 Address, get its properties and put them into the InterfaceAddrsArray.
		
		tmpAddrPtr = &((struct sockaddr_in *)ifa->ifa_addr)->sin_addr;
		char addressBuffer[INET_ADDRSTRLEN];
		inet_ntop(AF_INET, tmpAddrPtr, addressBuffer, INET_ADDRSTRLEN);
		tmpbroadPtr = &((struct sockaddr_in *)ifa->ifa_broadaddr)->sin_addr;
		
		//
		// I haven't found any clear way to determine if the interface is active.
        // The issue is that the IFM_ACTIVE flag indicates whether the interface is up and running,
        // but the IFM_ACTIVE flag does not exist on iOS.
        //
        // Furthermore, the IFF_UP and IFF_RUNNING flags are not sufficient to determine the state of interface.
        // These flags fail to indicate the correct status when the WIFI is down.
		
        // Therefore, the following code determines the availability of the cellular network and Wifi.
        // Only this information is used to determine whether the interface is active.
        // Note: The code assumes that the Wifi address is represented by "en0"
        // and the cellular network is represented by "pdp_xxx".
		
		
		// Create a zero address socket to determine if a connection is available.
        // If a connection is available, then either the Wifi or Cellular network or both are active.
		// Other flags are used to find out which network is active.
		
		struct sockaddr_in zeroAddress;
		bzero(&zeroAddress, sizeof(zeroAddress));
		zeroAddress.sin_len = sizeof(zeroAddress);
		zeroAddress.sin_family = AF_INET;
		SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr*)&zeroAddress);
		SCNetworkReachabilityFlags flags;
		
		BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
		CFRelease(defaultRouteReachability);
		
		if (!didRetrieveFlags)
		{
			return NULL;
		}
		
		BOOL isReachable = flags & kSCNetworkFlagsReachable;
		BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
		BOOL status = (isReachable && !needsConnection) ? YES : NO;
		
		
		if (status)
		{
			if (strcmp(ifa->ifa_name, "en0") == 0 )
			{
				NSLog(@"Check the Reachibility through Wifi ++++++++++++++++++++++++++++++++ ");
				
				if (!(flags & kSCNetworkReachabilityFlagsIsWWAN))
				{
					state = TRUE;
					FRENewObjectFromBool(state, &NetworkInterfaceArray[3]);
				}
				else
                {
					NSLog(@"Wifi is not Reachable ++++++++++++++++++++++++++++++++ ");
			    }
            }
	        else
		    {
				char *InterfaceStringPtr = ifa->ifa_name;
				NSString *string1 = [NSString stringWithCString:InterfaceStringPtr encoding:NSUTF8StringEncoding];
				
				if ([string1 rangeOfString:@"pdp"].location == NSNotFound)
				{
					NSLog(@"Device does not contain Cellular network");
				}
				else
				{
				    if ((flags & kSCNetworkReachabilityFlagsIsWWAN))
				    {
					    state = TRUE;
						FRENewObjectFromBool(state, &NetworkInterfaceArray[3]);
					}
				    else
                    {
						NSLog(@"Cellular  Connection is not Reachable ++++++++++++++++++++++++++++++++ ");
                    }
				}
				
		    }
			
		} // end if status is TRUE
		
		
		char broadCastAddressBuffer[INET_ADDRSTRLEN];
		inet_ntop(AF_INET, tmpbroadPtr, broadCastAddressBuffer, INET_ADDRSTRLEN);
        
        // Create a new ActionScript object for the IP address, and put it in InterfaceAddrsArray.
		FRENewObjectFromUTF8(INET_ADDRSTRLEN, (const uint8_t*)addressBuffer, &InterfaceAddrsArray[0]);
        
	    NSLog(@"IP4$ address ++++++++++++++++++++++++++++++++ %s",addressBuffer);
        // Create a new ActionScript object for the broadcast address, and put it in InterfaceAddrsArray.
        
        FRENewObjectFromUTF8(INET_ADDRSTRLEN, (const uint8_t*)broadCastAddressBuffer, &InterfaceAddrsArray[1]);
        
		NSLog(@"Broadcast$ address ++++++++++++++++++++++++++++++++ %s",broadCastAddressBuffer);
        // Create a new ActionScript object for the prefix length, and put it in InterfaceAddrsArray.
        
        // Note: The PrefixLength is not currently supported. It has the value -1.
        FRENewObjectFromInt32(PrefixLength , &InterfaceAddrsArray[2]);
		
        // Create a new ActionScript object for the ip version, and put it in InterfaceAddrsArray.
        iPVersion ="IPV4";
		FRENewObjectFromUTF8(32, (const uint8_t*)iPVersion, &InterfaceAddrsArray[3]);
		
	}
    
	else if (ifa->ifa_addr->sa_family==AF_INET6)
	{
        // else if the address is a valid IP6 Address, get its properties and put them into the InterfaceAddrsArray.
        
		tmpAddrPtr = &((struct sockaddr_in *)ifa->ifa_addr)->sin_addr;
		char addressBuffer[INET6_ADDRSTRLEN];
		inet_ntop(AF_INET6, tmpAddrPtr, addressBuffer, INET6_ADDRSTRLEN);
		
		char * broadCastForIpv6 = "";
		// A broadcast address is not applicable in IPV6
		
        // Create a new ActionScript object for the IP address, and put it in InterfaceAddrsArray.
        FRENewObjectFromUTF8(INET6_ADDRSTRLEN, (const uint8_t*)addressBuffer, &InterfaceAddrsArray[0]);
		NSLog(@"IP6$ address ++++++++++++++++++++++++++++++++ %s",addressBuffer);
		
        // Create a new ActionScript object for the broadcast address, and put it in InterfaceAddrsArray.
        FRENewObjectFromUTF8(INET_ADDRSTRLEN, (const uint8_t*)broadCastForIpv6, &InterfaceAddrsArray[1]);
		
        // Create a new ActionScript object for the prefix length, and put it in InterfaceAddrsArray.
        // Note: The PrefixLength is not currently supported. It has the value -1.
        FRENewObjectFromInt32(PrefixLength , &InterfaceAddrsArray[2]);
		
        // Create a new ActionScript object for the ip version, and put it in InterfaceAddrsArray.
        iPVersion ="IPV6";
		FRENewObjectFromUTF8(32, (const uint8_t*)iPVersion, &InterfaceAddrsArray[3]);
		
	}
	
	// Create an ActionScript InterfaceAddress object. InterfaceAddrsArray contains the parameters to the constructor.
    // Addrstemp is the corresponding FREObject for the new ActionScript object.
	
	if (FRE_OK !=
        FRENewObject((const uint8_t*)"com.sticksports.nativeExtensions.network.TempInterfaceAddress", 4, InterfaceAddrsArray, &Addrstemp, nil))
    {
		NSLog(@"FRENewObject failed; Addrstemp invalid.");
    }
	
    NSLog(@"Exiting getInterfaceProperties()");
    
	return Addrstemp;
}

void NetworkContextInitializer( void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet )
{
    static FRENamedFunction objectFunctionMap[] =
    {
        MAP_FUNCTION( findInterfaces, NULL )
    };
    
    *numFunctionsToSet = sizeof( objectFunctionMap ) / sizeof( FRENamedFunction );
    *functionsToSet = objectFunctionMap;
}

void NetworkContextFinalizer( FREContext ctx )
{
}

void NetworkExtensionInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet )
{
    extDataToSet = NULL;
    *ctxInitializerToSet = &NetworkContextInitializer;
    *ctxFinalizerToSet = &NetworkContextFinalizer;
}

void NetworkExtensionFinalizer()
{
    return;
}

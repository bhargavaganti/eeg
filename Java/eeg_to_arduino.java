import com.sun.jna.Pointer;
import com.sun.jna.ptr.IntByReference;
import com.illposed.osc.*;

import matlabcontrol.*;

import java.net.*;
import java.io.*;

/*
 * 
 * This class handles real-time recording and analysis of EEG data, as well as sending the resulting classification to an Arduino.
 * It records and analyzes data in 1-second intervals. 
 * Analysis is done in Matlab, which is called from this script via proxy.
 * This script communicates to an Arduino by sending an OSC message on local port 127.0.0.1. The message is then picked up by 
 * Processing and sent to the Arduino.
 * 
 */

public class eeg_to_arduino {
    public static void main(String[] args) 
    throws MatlabConnectionException, MatlabInvocationException, IOException, SocketException, UnknownHostException
    {
    	
    	// Set up OSC Out - send on port 4000 on localhost
    	InetAddress remoteIP = InetAddress.getByName("127.0.0.1");
    	int remotePort = 4000;
    	OSCPortOut sender = new OSCPortOut(remoteIP, remotePort);
    	
    	
    	// Set up MatlabControl
    	MatlabProxyFactoryOptions options = 
    		new MatlabProxyFactoryOptions.Builder()
    			.setUsePreviouslyControlledSession(true)
    			.build();
    	MatlabProxyFactory factory = new MatlabProxyFactory(options);
    	MatlabProxy proxy = factory.getProxy();
    	
    	// Any 'proxy.eval' calls are executing the contained strings as commands within the open Matlab session.
    	// This is going to the Matlab code directory, loading training data, and training an SVM.
    	proxy.eval("cd('~/Desktop/Duke/Spring 2016/ME 555 - HRI/EEG/Matlab');");
    	proxy.eval("data = load('cuttraining.mat');");
    	proxy.eval("m = fitcsvm(data.cutdata, data.Y, 'KernelFunction', 'linear');");
    	
    	
    	// Set up Emotiv
    	Pointer eEvent				= Edk.INSTANCE.EE_EmoEngineEventCreate();
    	Pointer eState				= Edk.INSTANCE.EE_EmoStateCreate();
    	IntByReference userID 		= null;
		IntByReference nSamplesTaken= null;
    	short composerPort			= 1726;
    	int option 					= 1;
    	int state  					= 0;
    	float secs 					= 1;
    	boolean readytocollect 		= false;
    	
    	userID 			= new IntByReference(0);
		nSamplesTaken	= new IntByReference(0);
    	
    	switch (option) {
		case 1:
		{
			if (Edk.INSTANCE.EE_EngineConnect("Emotiv Systems-5") != EdkErrorCode.EDK_OK.ToInt()) {
				System.out.println("Emotiv Engine start up failed.");
				return;
			}
			break;
		}
		case 2:
		{
			System.out.println("Target IP of EmoComposer: [127.0.0.1] ");

			if (Edk.INSTANCE.EE_EngineRemoteConnect("127.0.0.1", composerPort, "Emotiv Systems-5") != EdkErrorCode.EDK_OK.ToInt()) {
				System.out.println("Cannot connect to EmoComposer on [127.0.0.1]");
				return;
			}
			System.out.println("Connected to EmoComposer on [127.0.0.1]");
			break;
		}
		default:
			System.out.println("Invalid option...");
			return;
    	}
    	
		Pointer hData = Edk.INSTANCE.EE_DataCreate();
		Edk.INSTANCE.EE_DataSetBufferSizeInSec(secs);
		System.out.print("Buffer size in secs: ");
		System.out.println(secs);
    	
		// Start!
    	System.out.println("Start receiving EEG Data!");
    	long startTime = System.currentTimeMillis();
    	long curTime = startTime;
    	
    	// Never-ending while loop! This must be stopped by manual interruption. While going, it collects 1 second worth of data,
    	// performs FFT and SVM prediction in Matlab, then sends the prediction (1 or 0) as an OSC event to local port.
    	while(true) {
	    	Object[] direction = dataCollect(eEvent, state, userID, readytocollect, hData, nSamplesTaken, curTime, startTime, proxy);
	        double[] p = (double[]) direction[0];
	    	OSCMessage message1 = new OSCMessage("/a");
	    	message1.addArgument((int) p[0]);
	    	sender.send(message1);
	    	System.out.println("Sending: " + p[0]);
	    	startTime = System.currentTimeMillis();
	    	curTime = startTime;
    	}
    }
    
    // Data collection
    public static Object[] dataCollect(Pointer eEvent, int state, IntByReference userID, boolean readytocollect, Pointer hData, IntByReference nSamplesTaken, long curTime, long startTime, MatlabProxy proxy) 
    	throws MatlabConnectionException, MatlabInvocationException
    {
    	// Set up x as indexing variable and 'traces' as an empty matrix that will hold sensor values. Columns = electrodes.
    	proxy.eval("traces = zeros(180, 4);");
    	proxy.eval("x = 0;");
    	
    	double[] channels = new double[4];
    	
    	while (curTime < startTime + 1000) { // Loops for 1 second
    		
    		state = Edk.INSTANCE.EE_EngineGetNextEvent(eEvent);

			// New event needs to be handled
			if (state == EdkErrorCode.EDK_OK.ToInt()) 
			{
				int eventType = Edk.INSTANCE.EE_EmoEngineEventGetType(eEvent);
				Edk.INSTANCE.EE_EmoEngineEventGetUserId(eEvent, userID);

				// Log the EmoState if it has been updated
				if (eventType == Edk.EE_Event_t.EE_UserAdded.ToInt()) 
				if (userID != null)
					{
						System.out.println("User added");
						Edk.INSTANCE.EE_DataAcquisitionEnable(userID.getValue(),true);
						readytocollect = true;
					}
			}
			else if (state != EdkErrorCode.EDK_NO_EVENT.ToInt()) {
				System.out.println("Internal error in Emotiv Engine!");
				break;
			}
			
			// More Emotiv setup stuff
			Edk.INSTANCE.EE_DataUpdateHandle(0, hData);
			Edk.INSTANCE.EE_DataGetNumberOfSample(hData, nSamplesTaken);
	
			// This is basically the same sampling code as in training_sessions.java.
			if (nSamplesTaken != null)
			{
				if (nSamplesTaken.getValue() != 0) {
					double[] data = new double[nSamplesTaken.getValue()];
					for (int sampleIdx=0 ; sampleIdx < nSamplesTaken.getValue() ; ++ sampleIdx) {
						for (int i = 5 ; i <= 6 ; i++) { // Max value of i = number of columns
							// In above loop, sensor data are channels 3-16.
							// If changing number of times through this loop, change dividing print statement in startMessage
							Edk.INSTANCE.EE_DataGet(hData, i, data, nSamplesTaken.getValue());
							channels[i-5] = data[sampleIdx];
						}
						for (int i = 13 ; i <= 14 ; i++) {
							Edk.INSTANCE.EE_DataGet(hData, i, data, nSamplesTaken.getValue());
							channels[i-11] = data[sampleIdx];
						}
						// Each observation of sensor values is saved individually in a matrix within Matlab.
						// This process could be made more efficient by allocating an array in Java and sending all values at once.
						proxy.eval("x = x+1;");
						proxy.setVariable("newline", channels);
						proxy.eval("traces(x,:) = newline;");
					}
				}
			}
			curTime = System.currentTimeMillis();
    	}
    	proxy.eval("traces = traces(1:x, :);");
    	proxy.eval("x");
    	
    	// Returning the prediction of the SVM on the data 
    	Object[] prediction = proxy.returningEval("get_prediction(traces, m)", 1);
    	
    	double[] p = (double[]) prediction[0];
    	return prediction;
    }
}



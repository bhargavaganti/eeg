import com.sun.jna.Pointer;
import com.sun.jna.ptr.IntByReference;
import java.io.*;


/*
 * 
 * This class is for creating training session data. It records three 5-second intervals with prompts to remain neutral, move right arm,
 * and move left arm. A 3-second preparatory phase separates every 5-second recording time. All data is written to a file, and the three 
 * sections are separated in the file by printing a row of 0's. 
 * 
 */

public class training_sessions {
    public static void main(String[] args) 
    {
    	// Initialize variables for the Emotiv headset
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
    	
		// Check connectivity
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
    	
		// Make a file to write data and make a new BufferedWriter
		File file = null;
		BufferedWriter f = null;
		try {
			file = new File("/path/to/file/training_data/training_1.txt");
		      
			if (file.createNewFile()){
				System.out.println("File is created!");
			} else {
		        System.out.println("File already exists.");
		        System.exit(1);
			}
			
			f = new BufferedWriter(new FileWriter(file));
    	} catch (IOException e) {
		      e.printStackTrace();
		      System.exit(1);
		}
		
		// Indicate start of recording and log current time
    	System.out.println("Start receiving EEG Data!");
    	long startTime = System.currentTimeMillis();
    	long curTime = startTime;
    	
    	// Indicate start of each section with message function
    	message("remain neutral", curTime, startTime, f);
    	dataCollect(eEvent, state, userID, readytocollect, hData, nSamplesTaken, curTime, startTime, f);
    	startTime = System.currentTimeMillis();
    	curTime = startTime;
    	
    	message("move right arm", curTime, startTime, f);
    	dataCollect(eEvent, state, userID, readytocollect, hData, nSamplesTaken, curTime, startTime, f);
    	startTime = System.currentTimeMillis();
    	curTime = startTime;
    	
    	message("move left arm", curTime, startTime, f);
    	dataCollect(eEvent, state, userID, readytocollect, hData, nSamplesTaken, curTime, startTime, f);
    	startTime = System.currentTimeMillis();
    	curTime = startTime;
    	
    	// Disconnect program from headset after recording
    	Edk.INSTANCE.EE_EngineDisconnect();
    	Edk.INSTANCE.EE_EmoStateFree(eState);
    	Edk.INSTANCE.EE_EmoEngineEventFree(eEvent);
    	try {
			f.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
    	System.out.println("Done!");
    	System.out.println("Disconnected");
    }
    
    // Print message for next section and pause
    public static void message(String phase, long curTime, long startTime, BufferedWriter f) {
    	try {
			writeFile("0,0,0,0,0,0,0,0", f);
		} catch (IOException e) {
			e.printStackTrace();
		}
    	System.out.println("Prepare to " + phase);
    	// Pause for 3 seconds
    	while (curTime < startTime + 3000) { 
    		curTime = System.currentTimeMillis();
    	}
    	System.out.println("Sampling");
    }
    
    // Write data to file
    public static void writeFile(String text, BufferedWriter f) 
		throws IOException
		{ 
		  f.write(text);
		  f.newLine();
		}
    
    // Data collection
    public static void dataCollect(Pointer eEvent, int state, IntByReference userID, boolean readytocollect, Pointer hData, IntByReference nSamplesTaken, long curTime, long startTime, BufferedWriter f) {
    	while (curTime < startTime + 8000) { // Record from time = 3s to time = 8s
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
			Edk.INSTANCE.EE_DataUpdateHandle(0, hData);
	
			Edk.INSTANCE.EE_DataGetNumberOfSample(hData, nSamplesTaken);
	
			if (nSamplesTaken != null)
			{
				if (nSamplesTaken.getValue() != 0) {
					
					double[] data = new double[nSamplesTaken.getValue()];
					for (int sampleIdx=0 ; sampleIdx < nSamplesTaken.getValue() ; ++ sampleIdx) {
						String allData = "";
						for (int i = 3 ; i <= 6 ; i++) { // Max value of i = number of columns
							// In above loop, sensor data are channels 3-16.
							// If changing number of times through this loop, change dividing print statement in startMessage
							Edk.INSTANCE.EE_DataGet(hData, i, data, nSamplesTaken.getValue());
							allData = allData + String.valueOf(data[sampleIdx]);
							if (i != 6) { allData = allData + ","; }
						}
						for (int i = 13 ; i <= 16 ; i++) { // Max value of i = number of columns
							Edk.INSTANCE.EE_DataGet(hData, i, data, nSamplesTaken.getValue());
							allData = allData + String.valueOf(data[sampleIdx]);
							if (i != 16) { allData = allData + ","; }
						}
						try {
							writeFile(allData, f);
						} catch (IOException e) {
							e.printStackTrace();
						}
					}
				}
			}
			curTime = System.currentTimeMillis();
    	}
    }
}



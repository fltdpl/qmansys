package de.fltdpl.qmansis;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Set;
import java.util.UUID;
import java.util.Vector;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.preference.PreferenceManager;
import android.support.v7.app.ActionBarActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;



public class Bluetooth extends ActionBarActivity{
	
	private ProgressBar progressBar;
	TextView btstatus;
	Button kmsauto;
	Button kmsmanuell;
	TextView btinfo;
	TextView displayphase;
	TextView displaystatus;
	TextView displaytempmotor;
	TextView displaytempboiler;
	View rectangle_green;
	View rectangle_red;
	ArrayAdapter<String> listAdapter;
	BluetoothAdapter btAdapter;
	Set<BluetoothDevice> devicesArray;
	ArrayList<String> pairedDevices;
	ArrayList<BluetoothDevice> devices;
	BluetoothSocket mmSocket;
    BluetoothDevice mmDevice;
	IntentFilter filter;
	BroadcastReceiver receiver;
	String tag = "debugging";
	public static final UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
	protected static final int SUCCESS_CONNECT = 0;
	protected static final int MESSAGE_READ = 1;
	protected static final int MESSAGE_TOAST = 2;
	protected static final int MESSAGE_WRITE = 3;
	public static final String TOAST = "toast";
	Handler mHandler = new Handler(){
        @Override
        public void handleMessage(Message msg) {
        	super.handleMessage(msg);
        	
        	init();
        	switch(msg.what){
            case SUCCESS_CONNECT:
                // DO something
            	ConnectedThread connectedThread = new ConnectedThread((BluetoothSocket)msg.obj);
                btstatus.setText("Verbunden mit CANtoBT.");
                progressBar.setVisibility(4);									// lets make the progressbar invisible
                connectedThread.start();
                break;
            case MESSAGE_READ:
            	String string = (String)msg.obj;

                if(string.substring(0, 6).equals("43414e")){
                	String meta1  = string.substring(0, 6);
                	String meta2  = string.substring(6, 10);
                	String meta3  = string.substring(10, 12);
                	Integer mtemp  = Integer.parseInt(string.substring(12, 14), 16);
                	if (mtemp >= 200)
                		mtemp = mtemp - 256;
	                Integer btemp  = Integer.parseInt(string.substring(14, 16), 16);
	                if (btemp >= 200)
	                	btemp = btemp - 256;
	                Integer status = Integer.parseInt(string.substring(16, 18), 16);
	                Integer phase = Integer.parseInt(string.substring(18, 20), 16);
	                Log.i(tag, "Meta:  "+meta1+" "+meta2+" "+" "+meta3+" M:"+mtemp+" B:"+btemp+" S:"+status+" P:"+phase);
	                String txphase = null;
	                
	                switch(phase){
	                case 1:
	                	txphase = "Startphase";
	                	break;
	                case 2:
	                	txphase = "Vorwärmen des Kühlwassers";
	                	break;
	                case 3:
	                	txphase = "Warten...";
	                	break;
	                case 4:
	                	txphase = "Erwärmen des Boilerwassers";
	                	break;
	                case 5:
	                	txphase = "Manueller Betrieb";
	                	break;
	                case 6:
	                	txphase = "Manueller Betrieb";
	                	break;	                
	                }
	                //displayphase.setText(txphase);
	                if (txphase == null) {
	                	btinfo.setText(" ");
	                } else {
	                	btinfo.setText("Aktuelle Phase des Systems:\r\n"+txphase);
	                }
	                
	                
	                if (status.equals(0)){
	                	displaystatus.setText("AUS");
	                } else if (status.equals(1)){
	                	displaystatus.setText("AN");
	                } else {
	                	displaystatus.setText("Fehler");
	                }
	                displaytempmotor.setText(mtemp+" °C");
	                displaytempboiler.setText(btemp+" °C");
                }
            	
                break;
            case MESSAGE_WRITE:
            	String s = (String)msg.obj;
            	Log.i(tag, "senden: "+s);
            	ConnectedThread connectedThread2 = new ConnectedThread(mmSocket);
            	connectedThread2.write(s.getBytes());
            	break;
            case MESSAGE_TOAST:
            	Toast.makeText(getApplicationContext(), msg.getData().getString(TOAST),
            	Toast.LENGTH_LONG).show();
            	break;
            }
        }
    };
    
    
	

	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch(item.getItemId()){
		case R.id.status:
			try {
				mmSocket.close();
			} catch (IOException e) { }
			Intent m1 = new Intent("de.fltdpl.qmansis.STATUS");
			startActivity(m1);
			break;
		case R.id.about:
			Intent m3 = new Intent("de.fltdpl.qmansis.ABOUT");
			startActivity(m3);			
			break;
		case R.id.action_settings:
			try {
				mmSocket.close();
			} catch (IOException e) { }
			Intent m4 = new Intent("de.fltdpl.qmansis.SETTINGS");
			startActivity(m4);
			break;
		}
		return false;
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		super.onCreateOptionsMenu(menu);
		MenuInflater blowUp = getMenuInflater();
		blowUp.inflate(R.menu.bluetooth, menu);
		return true;
	}
	
	 @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_bluetooth);
	        
	        init();
	        
	        receiver = new BroadcastReceiver(){

				@Override
				public void onReceive(Context context, Intent intent) {
					SharedPreferences getPrefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
			    	String btdevicename    = getPrefs.getString("btdevice_preference", "0");
			    	if (btdevicename.isEmpty()){
			    		Toast.makeText(getApplicationContext(), "Bluetoothgerät unter Einstellungen angeben!", Toast.LENGTH_LONG).show();
						 finish();
			    	}
			    	
					String action = intent.getAction();
					
					if(BluetoothDevice.ACTION_FOUND.equals(action)){
	                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
	                    devices.add(device);
	                    //String s = "CANtoBT1";
	                    if(device.getName().equals(btdevicename)){
	                    	btstatus.setText("Modul gefunden...");
	                    	if(btAdapter.isDiscovering()){
	                            btAdapter.cancelDiscovery();
	                        }
	                    	ConnectThread connect = new ConnectThread(device);
	                        connect.start();
	                        Log.i(tag, "connect");
	                    }

	                } else if(BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action)){
	                    // run some code
	                	
	                } else if(BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)){
	                    // run some code
	                	
	                } else if(BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)){
	                    if(btAdapter.getState() == BluetoothAdapter.STATE_OFF){
	                        turnOnBT();
	                    }
	                }
				}
	        	
	        };
	        registerReceiver(receiver, filter);
	         filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
	        registerReceiver(receiver, filter);
	         filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
	        registerReceiver(receiver, filter);
	         filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
	        registerReceiver(receiver, filter);
	        
	        if(btAdapter == null){									// Wenn kein Bluetooth vorhanden ist
	        	Toast.makeText(getApplicationContext(), "Kein Bluetooth erkannt.", Toast.LENGTH_LONG).show();
	        	finish();
	        } else {												// Bluetooth vorhanden
	        	progressBar.setVisibility(0);						// lets make the progressbar visible
	        	if(!btAdapter.isEnabled()){							// Bluetooth ausgeschaltet?
	        		btstatus.setText("Bluetooth einschalten...");
	        		//turnOnBT();
	        		Toast.makeText(getApplicationContext(), "Bitte Bluetooth einschalten.", Toast.LENGTH_LONG).show();
		        	finish();
	        	}

	        	getPairedDevices();
	        	startDiscovery();
	        	
	        }
	        
	        kmsauto.setOnClickListener(new View.OnClickListener() {
	        	
				@Override
				public void onClick(View v) {
					String s = "AUTO";
					mHandler.obtainMessage(MESSAGE_WRITE, s).sendToTarget();  					
				}
			});
	        
	        kmsmanuell.setOnClickListener(new View.OnClickListener() {
				
				@Override
				public void onClick(View v) {
					String s = "MANU";
					mHandler.obtainMessage(MESSAGE_WRITE, s).sendToTarget();
				}
			});
	        
	        
	        
	 }

	private void startDiscovery() {
		btAdapter.cancelDiscovery();
		btAdapter.startDiscovery();
	}

	private void getPairedDevices() {
		btstatus.setText("Suche Bluetoothgerät...");
		devicesArray = btAdapter.getBondedDevices();
		if(devicesArray.size()>0){
			for(BluetoothDevice device:devicesArray){
				pairedDevices.add(device.getName());   
			}
		}
	}
	
	@Override
	 protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		 super.onActivityResult(requestCode, resultCode, data);
		 if(resultCode == RESULT_CANCELED){
			 Toast.makeText(getApplicationContext(), "Bluetooth muss eingeschaltet sein.", Toast.LENGTH_SHORT).show();
			 finish();
		 }
	 }

	private void turnOnBT() {
		Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
		startActivityForResult(intent, 1);
	}

	private void init() {
		rectangle_green = (View) findViewById(R.id.Rectangle_green);
        rectangle_green.setVisibility(0);								// alles im gruenen Bereich
        progressBar = (ProgressBar) findViewById(R.id.progressBar);
        progressBar.setVisibility(4);									// lets make the progressbar invisible
        btstatus 		  	= (TextView) findViewById(R.id.text_bluetoothstatus);
        btinfo				= (TextView) findViewById(R.id.text_info_bt);
        displayphase	  	= (TextView) findViewById(R.id.text_phase);
        displaystatus     	= (TextView) findViewById(R.id.text_status_pumpe_2);
        displaytempmotor  	= (TextView) findViewById(R.id.text_motortemperatur_2);
        displaytempboiler 	= (TextView) findViewById(R.id.text_boilertemperatur_2);
        btAdapter = BluetoothAdapter.getDefaultAdapter();				// Init Bluetoothadapter
        pairedDevices = new ArrayList<String>();
        devices = new ArrayList<BluetoothDevice>();
        filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
        kmsauto = (Button) findViewById(R.id.bt_button_automatik);
        kmsmanuell = (Button) findViewById(R.id.bt_button_manuell);
        
	}
	
	@Override
	protected void onPause() {
		super.onPause();
		unregisterReceiver(receiver);
		
	}
	
	private class ConnectThread extends Thread {
        
        //private final BluetoothSocket mmSocket;
        //private final BluetoothDevice mmDevice;
      
        public ConnectThread(BluetoothDevice device) {
            // Use a temporary object that is later assigned to mmSocket,
            // because mmSocket is final
            BluetoothSocket tmp = null;
            mmDevice = device;
			Log.i(tag, "construct");
            // Get a BluetoothSocket to connect with the given BluetoothDevice
            try {
                // MY_UUID is the app's UUID string, also used by the server code
                //tmp = device.createRfcommSocketToServiceRecord(MY_UUID);
                tmp = device.createInsecureRfcommSocketToServiceRecord(MY_UUID);
            } catch (IOException e) { 
                Log.i(tag, "get socket failed");
                 
            }
            mmSocket = tmp;
        }
      
        public void run() {
            // Cancel discovery because it will slow down the connection
            btAdapter.cancelDiscovery();
            Log.i(tag, "connect - run");
            try {
                // Connect the device through the socket. This will block
                // until it succeeds or throws an exception
                mmSocket.connect();
                Log.i(tag, "connect - succeeded");
            } catch (IOException connectException) {    
            	Log.i(tag, "connect failed");
            	// Send a failure message back to the Activity
        		Message msg = mHandler.obtainMessage(MESSAGE_TOAST);
        		Bundle bundle = new Bundle();
        		bundle.putString(TOAST, "Verbindung gescheitert");
        		msg.setData(bundle);
        		mHandler.sendMessage(msg);
        		finish();
                // Unable to connect; close the socket and get out
                try {
                    mmSocket.close();
                } catch (IOException closeException) { }
                return;
            }
      
            // Do work to manage the connection (in a separate thread)
            Log.i(tag, ""+mmSocket);
            mHandler.obtainMessage(SUCCESS_CONNECT, mmSocket).sendToTarget();
            
        }
        
        /** Will cancel an in-progress connection, and close the socket */
        public void cancel() {
            try {
                mmSocket.close();
            } catch (IOException e) { }
        }
    }
	
	private class ConnectedThread extends Thread {
        //private final BluetoothSocket mmSocket;
        private final InputStream mmInStream;
        private final OutputStream mmOutStream;
      
        public ConnectedThread(BluetoothSocket socket) {
            mmSocket = socket;
            InputStream tmpIn = null;
            OutputStream tmpOut = null;
      
            // Get the input and output streams, using temp objects because
            // member streams are final
            try {
                tmpIn = socket.getInputStream();
                tmpOut = socket.getOutputStream();
            } catch (IOException e) { 
            	Log.e(tag, "temp sockets not created", e);
            }
      
            mmInStream = tmpIn;
            mmOutStream = tmpOut;
        }
      
        public void run() {
        	Log.i(tag, "BEGIN mConnectedThread");
        	int bytes;
        	byte[] buffer;
        	
        	// Keep listening to the InputStream until an exception occurs
        	while (true) {
        		try {
                	Vector<String> stringVector = new Vector<String>();
                    int k = 1;
                    while (k<10){
                    	buffer = new byte[18];
                    	// Read from the InputStream
                		bytes = mmInStream.read(buffer);
                		String string = byteArrayToHexString(buffer);
                		
                    	int i = 1;
                    	String bstring = string;                    	
                    	while (i<=bytes){
                    		stringVector.add(bstring.substring(0, 2));
                        	bstring = bstring.substring(2, bstring.length());
                    		i++;
                    	};
                    	
                    	k = stringVector.size();
                    	//Log.i(tag, "byte:   "+bytes);
                    	//Log.i(tag, "string: "+string);
                    	
                    }
                    Log.i(tag, "vec1: "+stringVector);
                	while (!stringVector.firstElement().equals("43") && stringVector.size() > 10) {
                		stringVector.removeElementAt(0);
                	}
                	
                	Log.i(tag, "vec2: "+stringVector);
                	if (stringVector.size() > 10)
                		stringVector.setSize(10);
                	Log.i(tag, "vec3: "+stringVector);
                	if (stringVector.size() == 10){
                		if (stringVector.elementAt(0).equals("43") & 
                    			stringVector.elementAt(1).equals("41") &
                    			stringVector.elementAt(2).equals("4e")) {
                    		String message = stringVector.elementAt(0)+
                    				stringVector.elementAt(1)+
                    				stringVector.elementAt(2)+
                    				stringVector.elementAt(3)+
                    				stringVector.elementAt(4)+
                    				stringVector.elementAt(5)+
                    				stringVector.elementAt(6)+
                    				stringVector.elementAt(7)+
                    				stringVector.elementAt(8)+
                    				stringVector.elementAt(9);
                    		
                    		//Log.i(tag, "Message: "+message);
                    		// Send the obtained bytes to the UI Activity
                        	mHandler.obtainMessage(MESSAGE_READ, stringVector.size(), -1, message).sendToTarget();
                        	//Log.i(tag, ""+stringVector);
                    	}
                	}
                	
            	} catch (IOException e) {
            		connectionLost();
                	Log.e(tag, "disconnected", e);
                    break;
                    
                }
        		
        	}
        	
        }
        
      
        /* Call this from the main activity to send data to the remote device */
        public void write(byte[] bytes) {
            try {
                mmOutStream.write(bytes);
            } catch (IOException e) { }
        }
      
        /* Call this from the main activity to shutdown the connection */
        public void cancel() {
            try {
                mmSocket.close();
            } catch (IOException e) { }
        }
    }
	
	private void connectionLost() {
		// Send a failure message back to the Activity
		Message msg = mHandler.obtainMessage(MESSAGE_TOAST);
		Bundle bundle = new Bundle();
		bundle.putString(TOAST, "Verbindung getrennt.");
		msg.setData(bundle);
		mHandler.sendMessage(msg);
		finish();
		}
    
    public static String byteArrayToHexString(byte[] array) {
        StringBuffer hexString = new StringBuffer();
        for (byte b : array) {
          int intVal = b & 0xff;
          if (intVal < 0x10)
            hexString.append("0");
          hexString.append(Integer.toHexString(intVal));
        }
        return hexString.toString();    
      }
	
}

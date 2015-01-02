package de.fltdpl.qmansis;

import android.support.v7.app.ActionBarActivity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.telephony.SmsManager;

public class Status extends ActionBarActivity {
	
	private BroadcastReceiver mIntentReceiver;	
	private ProgressBar progressBar;
	Button status;
	Button kmson;
	Button kmsoff;
	TextView displaystatus;
	TextView displaytempmotor;
	TextView displaytempboiler;
	TextView displayfehler;
	View rectangle_green;
	View rectangle_red;
	int smsreceived;					// Kontrollflag zum Empfang einer angeforderten SMS
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// TODO Auto-generated method stub
		switch(item.getItemId()){
		case R.id.bluetooth:
			Intent m2 = new Intent("de.fltdpl.qmansis.BLUETOOTH");
			startActivity(m2);
			
			break;
		case R.id.about:
			Intent m3 = new Intent("de.fltdpl.qmansis.ABOUT");
			startActivity(m3);
			
			break;
		case R.id.action_settings:
			Intent m4 = new Intent("de.fltdpl.qmansis.SETTINGS");
			startActivity(m4);
			
			break;
		}
		return false;
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// TODO Auto-generated method stub
		super.onCreateOptionsMenu(menu);
		MenuInflater blowUp = getMenuInflater();
		blowUp.inflate(R.menu.status, menu);
		return true;
	}

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_status);
        
        rectangle_green = (View) findViewById(R.id.Rectangle_green);
        rectangle_green.setVisibility(0);								// alles im gruenen Bereich
        rectangle_red = (View) findViewById(R.id.Rectangle_red);
        rectangle_red.setVisibility(4);									// nix im roten Bereich
        status = (Button) findViewById(R.id.button_status);
        kmson  = (Button) findViewById(R.id.button_kmson);
        kmson.setEnabled(false);										// gray out the kmson-button 
        kmsoff = (Button) findViewById(R.id.button_kmsoff);
        kmsoff.setEnabled(false);										// gray out the kmsoff-button
        progressBar = (ProgressBar) findViewById(R.id.progressBar1);
        progressBar.setVisibility(4);									// lets make the progressbar invisible
        
        status.setOnClickListener(new View.OnClickListener() {
        	public void onClick(View v) {
        		sendSMS_STATUS();
        		progressBar.setVisibility(0);							// lets make the progressbar visible
        		
        		//30000 is the starting number (in milliseconds)
        		//1000 is the number to count down each time (in milliseconds)
        		Timeout counter = new Timeout(40000,1000);
        		counter.start();
        		
        		smsreceived = 0;										// Kontrollflag geloescht
        	}	
        });
        
        kmson.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				sendSMS_KMSON();				
			}
		});
        
        kmsoff.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				sendSMS_KMSOFF();
			}
		});
    }
    
    @Override
    protected void onResume() {
           super.onResume();
           
           IntentFilter intentFilter = new IntentFilter("SmsMessage.intent.STATUS");
           mIntentReceiver = new BroadcastReceiver() {
        	   
        	   @Override
               public void onReceive(Context context, Intent intent) {
        		   String msg = intent.getStringExtra("get_msg");
        		   
        		   // Process the sms format and extract body and phoneNumber
        		   msg = msg.replace("\n", "/");			// Replace Return mit /
        		   msg = msg.replace(" ", "/");				// Replace Space mit /
        		   String body = msg.substring(msg.lastIndexOf(":") + 1, msg.length());
        		   String pNumber = msg.substring(0, msg.lastIndexOf(":"));
        		   // Debugging
        		   Log.e("onResume", "" + msg + body + pNumber);
        		   
	               String bodytemp     = body.substring(0, body.lastIndexOf("/"));
	               String instatus     = body.substring(body.lastIndexOf("/") +1, body.length());
	               String intempmotor  = bodytemp.substring(0, bodytemp.lastIndexOf("/"));
	               String intempboiler = bodytemp.substring(bodytemp.lastIndexOf("/") + 1, bodytemp.length());
	               
	               displaystatus     = (TextView) findViewById(R.id.text_status_pumpe_2);
	               displaytempmotor  = (TextView) findViewById(R.id.text_motortemperatur_2);
	               displaytempboiler = (TextView) findViewById(R.id.text_boilertemperatur_2);
	               if (instatus.equals("ON")) {
	            	   displaystatus.setText("An");
	               }else{
	            	   displaystatus.setText("Aus");
	               };
	               displaytempmotor.setText(intempmotor + "°C");
	               displaytempboiler.setText(intempboiler + "°C");
	               
	               progressBar.setVisibility(8);						// and the progressbar should be invisible again...
	               kmson.setEnabled(true);								// lets make the kmson-button work
	               kmsoff.setEnabled(true);								// lets make the kmsoff-button work
	               
	               smsreceived = 1;										// Kontrollflag setzten: Nachricht empfangen
	               displayfehler.setText("Kein Fehler.");
	               rectangle_green.setVisibility(0);					// alles im gruenen Bereich
	               rectangle_red.setVisibility(4);
        	   }
        	   
           };
           this.registerReceiver(mIntentReceiver, intentFilter);
    }
    
    @Override
    protected void onPause() {

           super.onPause();
           this.unregisterReceiver(this.mIntentReceiver);
    }
    
    
    public void sendSMS_STATUS() {
    	
    	SharedPreferences getPrefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
    	String Telnummer    = getPrefs.getString("editnumber_preference", "0");
    	String Telnachricht = "STATUS";
    	
    	SmsManager smsManager = SmsManager.getDefault();
    	smsManager.sendTextMessage(Telnummer, null, Telnachricht, null, null);
    	
    	// Debugging
    	Log.e("sendSMS_STATUS", Telnummer + " / " + Telnachricht);    	
    	
    }
    
    public void sendSMS_KMSON() {
    	
    	SharedPreferences getPrefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
    	String Telnummer    = getPrefs.getString("editnumber_preference", "0");
    	String Telnachricht = "KMSON";
    	
    	SmsManager smsManager = SmsManager.getDefault();
    	smsManager.sendTextMessage(Telnummer, null, Telnachricht, null, null);
    	
    	// Debugging
    	Log.e("sendSMS_KMSON", Telnummer + " / " + Telnachricht);    	
    	
    }
    
    public void sendSMS_KMSOFF() {
    	
    	SharedPreferences getPrefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
    	String Telnummer    = getPrefs.getString("editnumber_preference", "0");
    	String Telnachricht = "KMSOFF";
    	
    	SmsManager smsManager = SmsManager.getDefault();
    	smsManager.sendTextMessage(Telnummer, null, Telnachricht, null, null);
    	
    	// Debugging
    	Log.e("sendSMS_KMSOFF", Telnummer + " / " + Telnachricht);    	
    	
    }
    
  //countdowntimer is an abstract class, so extend it and fill in methods
    public class Timeout extends CountDownTimer{
    	public Timeout(long millisInFuture, long countDownInterval) {
    		super(millisInFuture, countDownInterval);
    }

    @Override
    public void onFinish() {												// Timer ist abgelaufen
    	 progressBar.setVisibility(8);										// and the progressbar should be invisible again...
    	 displayfehler = (TextView) findViewById(R.id.text_fehler);
    	 if (smsreceived == 1){
    		 displayfehler.setText("Kein Fehler.");
    	    rectangle_green.setVisibility(0);								// alles ok, darum gruen
    	    rectangle_red.setVisibility(4);
    	 } else {
    		 displayfehler.setText("Keine Antwort erhalten.");
    	     rectangle_green.setVisibility(4);
    	     rectangle_red.setVisibility(0);								// Fehler wird mit rot quitiert
    	 }
    	
    }
    
    @Override
    public void onTick(long millisUntilFinished) {							// Waehrend der Timer laeuft...
    	displayfehler = (TextView) findViewById(R.id.text_fehler);
    	if (millisUntilFinished <= 20000) {
    		displayfehler.setText("Anfrage dauert an...");
    		rectangle_green.setVisibility(0);								// alles im gruenen Bereich
            rectangle_red.setVisibility(4);
    	} else {
    		displayfehler.setText("...");
    		rectangle_green.setVisibility(0);								// alles im gruenen Bereich
            rectangle_red.setVisibility(4);
    	}
    	
    	if (smsreceived == 1){
    		onFinish();
    		displayfehler.setText("Kein Fehler.");
    		}  
    		

    }
    
    }
    
}
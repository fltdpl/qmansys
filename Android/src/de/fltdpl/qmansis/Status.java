package de.fltdpl.qmansis;

import android.support.v7.app.ActionBarActivity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Bundle;
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
	TextView displaystatus;
	TextView displaytempmotor;
	TextView displaytempboiler;
	
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// TODO Auto-generated method stub
		switch(item.getItemId()){
		case R.id.about:
			Intent i = new Intent("de.fltdpl.qmansis.ABOUT");
			startActivity(i);
			
			break;
		case R.id.action_settings:
			Intent s = new Intent("de.fltdpl.qmansis.SETTINGS");
			startActivity(s);
			
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
        
        status = (Button) findViewById(R.id.button_status);
        progressBar = (ProgressBar) findViewById(R.id.progressBar1);
        progressBar.setVisibility(4);
        status.setOnClickListener(new View.OnClickListener() {
        	
        	public void onClick(View v) {
        		sendSMS_STATUS();
        		progressBar.setVisibility(0);
        		
        		
        		
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
        		   msg = msg.replace("\n", "/");
        		   String body = msg.substring(msg.lastIndexOf(":") + 1, msg.length());
        		   String pNumber = msg.substring(0, msg.lastIndexOf(":"));
        		   // Debugging
        		   Log.e("onResume", "" + msg + body + pNumber);
        		   
	               String bodytemp     = body.substring(0, body.lastIndexOf("/"));
	               String instatus     = bodytemp.substring(0, bodytemp.lastIndexOf("/"));
	               String intempmotor  = bodytemp.substring(bodytemp.lastIndexOf("/") + 1, bodytemp.length());
	               String intempboiler = body.substring(body.lastIndexOf("/") +1, body.length());
	               
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
	               
	               progressBar.setVisibility(8);
	               
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
    	//String Telnummer    = "017663119724";
    	String Telnachricht = "STATUS";
    	
    	SmsManager smsManager = SmsManager.getDefault();
    	smsManager.sendTextMessage(Telnummer, null, Telnachricht, null, null);
    	
    	// Debugging
    	Log.e("sendSMS_STATUS", Telnummer + " / " + Telnachricht);
    	
    	
    }
    
    
    
}

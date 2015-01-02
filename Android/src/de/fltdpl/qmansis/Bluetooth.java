package de.fltdpl.qmansis;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;

public class Bluetooth extends ActionBarActivity{
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// TODO Auto-generated method stub
		switch(item.getItemId()){
		case R.id.status:
			Intent m1 = new Intent("de.fltdpl.qmansis.STATUS");
			startActivity(m1);
			
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
		blowUp.inflate(R.menu.bluetooth, menu);
		return true;
	}
	
	 @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_bluetooth);
	        
	 }
	

}

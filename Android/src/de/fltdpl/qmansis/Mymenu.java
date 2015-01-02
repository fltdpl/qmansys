package de.fltdpl.qmansis;

import android.app.ListActivity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.ListView;

public class Mymenu extends ListActivity{
	
	String classes[] = { "Status", "Bluetooth", "Settings"};
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onCreate(savedInstanceState);
		setListAdapter(new ArrayAdapter<String>(Mymenu.this, android.R.layout.simple_list_item_1, classes));
	}
			
	@Override
	protected void onListItemClick(ListView l, View v, int position, long id) {
		// TODO Auto-generated method stub
		super.onListItemClick(l, v, position, id);
		String geklickt = classes[position];
		try{
			Class ourClass = Class.forName("de.fltdpl.qmansis." + geklickt);
			Intent ourIntent = new Intent(Mymenu.this, ourClass);
			startActivity(ourIntent);
		}catch(ClassNotFoundException e){
			e.printStackTrace();
		}
	}

}

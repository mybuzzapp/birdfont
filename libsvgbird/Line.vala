/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using Cairo;

namespace SvgBird {

public class Line : Object {	

	public double x1 = 0;
	public double y1 = 0;
	public double x2 = 0;
	public double y2 = 0;
	
	public Line () {
	}

	public Line.create_copy (Line c) {
		Object.copy_attributes (c, this);
		c.x1 = x1;
		c.y1 = y1;
		c.x2 = x2;
		c.y2 = y2;
	}
	
	public override bool is_over (double x, double y) {
		return false;
	}
			
	public override void draw (Context cr) {
		cr.save ();
		cr.move_to (x1, y1);
		cr.line_to (x1, y1);
		cr.line_to (x2, y2);
		apply_transform (cr);		
		paint (cr);
		cr.restore ();
	}

	public override void move (double dx, double dy) {
	}
	
	public override void update_region_boundaries () {
	}

	public override void rotate (double theta, double xc, double yc) {
	}
	
	public override bool is_empty () {
		return false;
	}
	
	public override void resize (double ratio_x, double ratio_y) {
	}
	
	public override Object copy () {
		return new Line.create_copy (this);
	}

	public override string to_string () {
		return "Line";
	}
}

}

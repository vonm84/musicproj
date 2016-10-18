
  
function changerect(i)
{
  var elem = document.getElementById('canv_'+i);
  if (elem != null) {elem.remove()}
  var vals = getElementsStartsWithId('vals_box');
  var percs = getElementsStartsWithId('perc');
  var allvals = 0;
  for (var j = 0; j < vals.length; j++) {
    allvals+=parseInt(vals[j].value);
  }
  for (j = 0; j < percs.length; j++) {
    percs[j].innerHTML=(100*(parseInt(vals[j].value)/allvals)).toFixed(2) + "%";
  }

  var x = 0;
  var y = 10;
  var width = 20;
  var height = 2*document.getElementById('vals_box_'+i).value;
  var canvas = document.createElement('canvas');

  canvas.setAttribute("id","canv_"+i);

  canvas.width = 20;//window.innerWidth;
  canvas.height = 200;//window.innerHeight;
  //Position canvas
  canvas.style.position='relative';
  canvas.textAlign='center';
  canvas.style.left=0;
  canvas.style.top=100;
  canvas.style.zIndex=100000;
  canvas.style.pointerEvents='none'; //Make sure you can click 'through' the canvas
  document.body.appendChild(canvas);
  document.getElementById('distrib_'+i).appendChild(canvas);//Append canvas to body element
  var context = canvas.getContext('2d');
  context.clearRect(x, y, canvas.width, canvas.height);
  //Draw rectangle
  context.rect(x, y, width, height);
  context.fillStyle = 'black';
  context.fill();
}

function update() {
  var vals = getElementsStartsWithId('vals_box');
  var valvals = [];
  var extendedvalslen= parseInt(document.getElementById('binomial_box').value);
  if ( extendedvalslen >200){
    alert ("Value must be less than 200");
    return;
  }
  
  extendedvalslen+= !(extendedvalslen % 2);

  
  var extendedvals = new Array (extendedvalslen);
  
  for (var j = 0; j < extendedvals.length; j++) {
    extendedvals[j]=binomial(extendedvals.length+1,j+1);
  }
  if (extendedvals.length >= vals.length){
    for (j = 0; j < vals.length; j++) {
      vals[j].value=extendedvals[j+Math.abs(Math.ceil(vals.length/2)-Math.ceil(extendedvals.length/2))];
      valvals[j]=vals[j].value;
    }
}
  else{
    for (j = 0; j < vals.length; j++) {
      vals[j].value=extendedvals[j-Math.abs(Math.ceil(vals.length/2)-Math.ceil(extendedvals.length/2))];
      valvals[j]=vals[j].value;
    }
  }
  
  
  for (j = 0; j < vals.length; j++) {
    vals[j].value=parseInt(100* vals[j].value/getMaxOfArray(valvals));
    changerect(j);
  }
  

}


function getElementsStartsWithId( id ) {
  var children = document.body.getElementsByTagName('*');
  var elements = [], child;
  for (var i = 0, length = children.length; i < length; i++) {
    child = children[i];
    if (child.id.substr(0, id.length) == id)
      elements.push(child);
  }
  return elements;
}


function binomial(n, k) {  
     if ((typeof n !== 'number') || (typeof k !== 'number'))   
  return false;   
    var coeff = 1;  
    for (var x = n-k+1; x <= n; x++) coeff *= x;  
    for (x = 1; x <= k; x++) coeff /= x;  
    return coeff;  
}  

function getMaxOfArray(numArray) {
  return Math.max.apply(null, numArray);
}


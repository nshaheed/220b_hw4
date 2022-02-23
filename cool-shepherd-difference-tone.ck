//--------------------------------------------------------------------
// name: shepard.ck
// desc: continuous shepard-risset tone generator; 
//       ascending but can easily made to descend
//
// author: Ge Wang (https://ccrma.stanford.edu/~ge/)
//   date: spring 2016
//--------------------------------------------------------------------

// mean for normal intensity curve
66 => float MU;
// standard deviation for normal intensity curve
44 => float SIGMA;
// normalize to 1.0 at x==MU
1 / gauss(MU, MU, SIGMA) => float SCALE;
// increment per unit time (use negative for descending)
.0004 => float INC;
// unit time (change interval)
1::ms => dur T;

// starting pitches (in MIDI note numbers, octaves apart)
[ 12.0, 24, 36, 48, 60, 72, 84, 96, 108] @=> float pitches[];
// number of tones
pitches.size() => int N;
// bank of tones
TriOsc tones[N];
float gains[N];
// overall gain
Gain gain => dac; 1.0/N => gain.gain;
// connect to dac
for( int i; i < N; i++ ) { 
    tones[i] => gain; 
    if (i < 3) {
        1 => gains[i];
    } else {
        0 => gains[i];
    }
}

1 => int keepGoing;
fun void modifyTones() {
    3 => int counter;
    5::second => dur amount;
    
    1::minute => now;
    while (counter < N) {
        
        <<< "adding new osc", counter >>>;
        1 => gains[counter];
        
        counter++;
        amount => now;
        amount - 0.3::second => amount;

    }
    
    10::second => now;
    
    0 => keepGoing;

}

spork~ modifyTones();

 

// infinite time loop
while( keepGoing )
{
    for( int i; i < N; i++ )
    {
        // set frequency from pitch
        pitches[i] => Std.mtof => tones[i].freq;
        // if (i == 0) <<< tones[i].freq() >>>;
        // compute loundess for each tone
        gauss( pitches[i], MU, SIGMA ) * SCALE => float intensity;
        // map intensity to amplitude
        gains[i]*intensity*96 => Math.dbtorms => tones[i].gain;
        // increment pitch
        INC +=> pitches[i];
        // wrap (for positive INC)
        if( pitches[i] > 48 ) { 
            108 -=> pitches[i];
        }
        // wrap (for negative INC)
        else if( pitches[i] < 12 ) 108 +=> pitches[i];
    }
    
    // advance time
    T => now;
}

<<< "past loop" >>>;
10::second => now;

// normal function for loudness curve
// NOTE: chuck-1.3.5.3 and later: can use Math.gauss() instead
fun float gauss( float x, float mu, float sd )
{
    return (1 / (sd*Math.sqrt(2*pi))) 
           * Math.exp( -(x-mu)*(x-mu) / (2*sd*sd) );
}

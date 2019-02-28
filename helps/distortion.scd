(
{
	var x = SinOsc.ar(220, 0, 0.8);
	var amount = MouseX.kr(-1, 1);
	var k = 2 * amount / (1 - amount);
	(1 + k) * x / (1 + (k * x.abs));
}.scope

)

(
{
	var in, amount, amCoef;
	in = HPF.ar(SoundIn.ar(5), 400)*5;
	amount = 0.99;
	amCoef= 2*amount/(1-amount);
	MidEQ.ar(LPF.ar((1+amCoef)*in/(1+(amCoef*in.abs)), [2400,2400])*0.5, 120, 0.7, 0, 0.2);
}.play;
)
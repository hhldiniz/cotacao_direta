

abstract class HomeViewModel
{
  Future<double> loadDollarValue();
  Future<double> loadEuroValue();
  Future<double> loadCanadianDollar();
  Future<double> loadYen();
  loadData();
  Sink get currencyMultiplierValue;
  dispose();
}
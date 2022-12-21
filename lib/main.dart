import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  runApp(
    MaterialApp(
      title: "GQL App",
      home: MyApp(),
      theme: ThemeData(primarySwatch: Colors.pink, accentColor: Colors.black),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink("https://countries.trevorblades.com/");
    final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(
            // dataIdFromObject: typename,

            ),
      ),
    );
    return GraphQLProvider(
      child: HomePage(),
      client: client,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String queryAll = r"""
                    query {
                      continents {
                        name
                        code
                      }
                    }
                  """;
  int selected = 0; //attention

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Continents"),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(queryAll),
        ),
        builder: (QueryResult result,
            {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.data == null) {
            return const Text("No Data Found !");
          }
          return ListView.builder(
            key: Key('builder ${selected.toString()}'), //attention

            itemBuilder: (BuildContext context, int index) {
              return ExpansionTile(
                  key: Key(index.toString()), //attention
                  initiallyExpanded: index == selected, //attention
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(result.data?['continents'][index]['name']),
                  children: [
                    SizedBox(
                        height: 300,
                        child: Item(result.data?['continents'][index]['code']))
                  ],
                  onExpansionChanged: ((newState) {
                    if (newState) {
                      setState(() {
                        const Duration(seconds: 20000);
                        selected = index;
                      });
                    } else {
                      setState(() {
                        selected = -1;
                      });
                    }
                  }));
            },
            itemCount: result.data?['continents']?.length,
          );
        },
      ),
    );
  }
}

class Item extends StatelessWidget {
  final selectedCode;
  const Item(this.selectedCode, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String query = r"""
                    query GetContinent($code : ID!){
                      continent(code:$code){
                        name
                        countries{
                          name
                        }
                      }
                    }
                  """;

    return Query(
        options: QueryOptions(
            document: gql(query),
            variables: <String, dynamic>{"code": selectedCode}),
        builder: (QueryResult result,
            {VoidCallback? refetch, FetchMore? fetchMore}) {
          // print('query individual $result');
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.data == null) {
            return const Text("No Data Found !");
          }
          return ListView.builder(
              itemCount: result.data?['continent']['countries']?.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => IndividualItem(
                                item: (result.data?['continent']['countries']
                                    [index] as Map<String, dynamic>),
                              )),
                    );
                  },
                  child: Card(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      decoration:
                          BoxDecoration(color: Theme.of(context).accentColor),
                      child: Text(
                        result.data?['continent']['countries'][index]['name'],
                        style: TextStyle(
                            color: Theme.of(context).primaryColorLight),
                      ),
                    ),
                  ),
                );
              });
        });
  }
}

class IndividualItem extends StatelessWidget {
  Map<String, dynamic> item = {};
  IndividualItem({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item['name'])),
      body: Card(
        color: Theme.of(context).accentColor,
        elevation: 5,
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'The name of the city is ${item['name']} which makes it a beautiful city. it is (the distance) from the capital. It has a population of 1000 approx. I live with my family consisting of my father, mother, younger brothers, grandparents, uncles, and their children. My ancestors were born in this city; it is the home of my family since ancient times. My family works in the field of (work name), which is the work of most of the people of the city where I live. I receive my education at the school (name of the school), one of the city schools. It was bult since a long time. My father, my mother and my uncles learned at this school. My city has all the services. We have a market (market name) that provides the city with all its requirements of vegetables, fruits, meat, fish, poultry, grains, tools, fabrics and other products.',
              style: TextStyle(color: Theme.of(context).primaryColorLight),
            )),
      ),
    );
  }
}

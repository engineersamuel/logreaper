import { Component, PropTypes } from "react";

import fetch            from 'isomorphic-fetch';
import Uri              from 'jsuri';
import DataGrid         from 'react-datagrid';
import { Glyphicon }    from "react-bootstrap"


class Recommendations extends Component {
    constructor(props, context) {
        super(props, context);
        this.state = {
            loading: false,
            recommendations: []
        }
    }
    _genRecommendationPromise(url, text) {
        return fetch(url, {
            method: 'post',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({text: text})
        }).then(response => response.json())
    }
    searchForRecommendations(texts) {
        if (!texts) return null;

        let sanitizedTexts = _.chain(texts).map(t => t.trim()).without(null, '').uniq().value();

        if (sanitizedTexts.length > 0) {
            let uri = new Uri("/labs/logreaper/recommendations");
            uri.addQueryParam('rows', 1);
            let recommendations = [];

            this.setState({loading: true});
            Promise.all(_.map(sanitizedTexts, t => this._genRecommendationPromise(uri.toString(), t))).then(responses => {
                // Iterate through each set of results for each recommendation
                _.each (responses, r => {
                    if (r && r.length > 0) {
                        recommendations.push(r)
                    }
                });
                // Since there are 1 or more recommendations in each response, flatten all the recommendations
                recommendations = _.chain(recommendations).flatten().uniqBy('id').value();
                // Add an index for each recommendation so the datagrid can be properly initialized
                recommendations.forEach((r, idx) => r.compound = {nid: r.id, view_uri: r.view_uri});
                this.setState({recommendations: recommendations, loading: false});
            }).catch(e => {
                this.setState({loading: false});
                console.error(e);
            });
        }

    }
    componentWillReceiveProps(nextProps) {
        this.searchForRecommendations(nextProps.texts)
    }
    componentDidMount() {
        this.searchForRecommendations(this.props.texts);
    }
    render() {
        return (
            <div>
                <small>Click a <Glyphicon className="green" glyph="filter"></Glyphicon> to focus these recommendations.</small>
                <DataGrid
                    idProperty="id"
                    dataSource={this.state.recommendations}
                    loading={this.state.loading}
                    columns={this.props.columns}
                    showCellBorders={true}
                    style={{height: this.props.height || 300}}>
                </DataGrid>
            </div>

        );
    }
}

Recommendations.defaultProps = {
    columns: [
        {
            name: 'compound',
            title: 'Solution',
            width: 70,
            render: (obj) => {
                return <a target="_blank" href={`${obj.view_uri}`}>{obj.nid}</a>;
            }
        },
        {
            name: 'allTitle',
            title: 'Title'
        }
    ]
};

Recommendations.propTypes = {
    texts: PropTypes.array.isRequired,
    columns: PropTypes.array,
    height: PropTypes.number
};

export default Recommendations;

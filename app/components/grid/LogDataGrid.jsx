import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import DataGrid from 'react-datagrid';
import { Row, Col } from "react-bootstrap"

import Spacer from '../Spacer.jsx'

class LogDataGrid extends Component {
    constructor(props, context) {
        super(props, context);
        //this.onRowClick = this.onRowClick.bind(this);
        this.onSelectionChange = this.onSelectionChange.bind(this);
        this.state = {
            selectedRow: null
        }
    }

    //shouldComponentUpdate(nextProps, nextState) {
    //    return !shallowEqual(this.props, nextProps) || !shallowEqual(this.state, nextState);
    //}

    renderCol(key, item) {
        return (
            <Row key={key}>
                <Col md={2}>
                    <strong>{key}</strong>
                </Col>
                <Col md={10}>
                    <pre>{item[key]}</pre>
                </Col>
            </Row>
        )
    }

    renderSelectedRow(item) {
        if (item == null) return null;
        return (
            <Row>
                <hr />
                <h3>Selected Row:</h3>
                {_.chain(item).keys().without('idx', 'fileName').map(k => this.renderCol(k, item)).value()}
            </Row>
        )
    }

    onSelectionChange(newIdx, item) {
        this.SELECTED_ID = newIdx;
        this.setState({selectedRow: newIdx != null ? item : null});
    }

    render() {
        if (this.props.data == null) return null;
        const {data, columns, height, idProperty, cap} = this.props;

        if (this.SELECTED_ID == null) {
            this.SELECTED_ID = data[0] && data[0].idx;
        }

        return (
            <div>
                <h3>Log Entries</h3>
                <small>Capped at {cap}, click a row to view the entry</small>
                <Spacer />
                <DataGrid
                    idProperty={idProperty || "id"}
                    dataSource={data}
                    columns={columns}
                    //pagination={isPaged || false}
                    onSelectionChange={this.onSelectionChange}
                    //onRowClick={this.onRowClick}
                    selected={this.SELECTED_ID}
                    showCellBorders={true}
                    style={{height: height || 500}}>
                </DataGrid>
                <Spacer size={60} />
                {this.renderSelectedRow(this.state.selectedRow)}
            </div>
        )
    }
}

LogDataGrid.propTypes = {
    data: PropTypes.array.isRequired,
    idProperty: PropTypes.string,
    columns: PropTypes.array.isRequired,
    cap: PropTypes.number.isRequired,
    height: PropTypes.number,
    isPaged: PropTypes.bool
};

export default LogDataGrid;

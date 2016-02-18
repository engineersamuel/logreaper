import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { Row, Col, Glyphicon } from "react-bootstrap"

import Spacer           from '../Spacer.jsx'
import DivOrSpan        from '../DivOrSpan.jsx'

class TopCounts extends Component {

    //shouldComponentUpdate(nextProps, nextState) {
    //    return !shallowEqual(this.props.progress, nextProps.progress);
    //}

    //filtersContainItem(item) {
    //  return _.findIndex(this.props.filters, item) != -1
    //}

    transformItem(item) {
      return {field: this.props.field.charAt(0).toLowerCase() + this.props.field.slice(1), key: item.key}
    }

    onClick(item, e) {
        e.preventDefault();

        item = this.transformItem(item);

        if (this.isItemFiltered(item)) {
            this.props.removeFilter(item)
        } else {
            this.props.addFilter(item);
        }
    }

    createSeverityClass(sev) {
      return sev != null ? "severity-#{sev}" : "";
    }

    /*item = {
     field: ...,
     value: (this is actually the key!)
     }*/
    isItemFiltered(item) {
        item = this.transformItem(item);
        return _.findIndex(this.props.filters, item) !== -1;
    }
    renderFilterIcon(item) {
        if (this.isItemFiltered(item)) {
            return <Glyphicon className="black" glyph="remove"></Glyphicon>;
        } else {
            return <Glyphicon className="green" glyph="filter"></Glyphicon>;
        }
    }

    renderTopPercentage(count, idx) {
        if (this.props.showTopPercentage != null && (idx < this.props.showTopPercentage)) {
            let percentage = ((count / this.props.cfSize) * 100).toFixed(0);
            return <span>(comprises {percentage}% of entries)</span>
        }
    }

    renderItem(item, idx) {
        let truncatedValue = _.truncate(item.key, {length: this.props.truncate});
        // TODO -- Need to compute the style here with the colors

        //<span className="meta_portal_tag top-field-item">
        return (
            <DivOrSpan inline={this.props.inline} key={`top-${this.props.field}-${idx}`}>
                <a className="pointer" onClick={this.onClick.bind(this, item)}>
                    {this.renderFilterIcon(item)}
                </a>
                &nbsp;
                <strong>{_.get(item, 'value.count', item.value)}</strong>
                &nbsp;
                <span className="field-item taxonomy-list taxonomy-portal_tag">
                    <span>{truncatedValue}</span>
                    &nbsp;&nbsp;
                    {this.renderTopPercentage(_.get(item, 'value.count', item.value), idx)}
                </span>
                &nbsp;
            </DivOrSpan>
        )
    }

    renderItems() {
        // Prob need to wrap in a div
        return this.props.group.top(this.props.topSize || 5).map((item, idx) => this.renderItem(item, idx));
    }

    render() {
        return (
            <div>
                {this.renderItems()}
            </div>
        )
    }
}

TopCounts.defaultProps = {
    truncate: 40
};

TopCounts.propTypes = {
    addFilter: PropTypes.func.isRequired,
    removeFilter: PropTypes.func.isRequired,
    filters: PropTypes.array.isRequired,
    field: PropTypes.string.isRequired,
    group: PropTypes.object.isRequired,
    cfSize: PropTypes.number.isRequired,
    truncate: PropTypes.number,
    topSize: PropTypes.number,
    inline: PropTypes.bool
};

export default TopCounts;

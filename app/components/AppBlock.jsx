import { Component, PropTypes } from "react";

export default class AppBlock extends Component {
    render() {
        if (this.props.render == false) return null;
        const {title, small} = this.props;
        return  (
            <div className="app-block">
                <h3 className="title">
                    <span>{title}</span>
                    <small style={{color: 'black'}}>&nbsp;{small}</small>
                </h3>
                <div className="content">
                    {this.props.children}
                </div>
            </div>
        )
    }
}

AppBlock.propTypes = {
    title: PropTypes.string.isRequired,
    render: PropTypes.bool,
    small: PropTypes.string
};

export default AppBlock;
